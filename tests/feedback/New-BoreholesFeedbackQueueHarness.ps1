<#
.SYNOPSIS
Inspect or emit an isolated source-derived feedback queue test; never executes it.
.DESCRIPTION
Emission requires the inspected source hash and nonce. Generated SQL creates and
drops only one nonce private temporary table; production tables are never read or
written. The original payload-only harness remains unchanged.
#>
[CmdletBinding()]
param(
    [switch]$AsSql,
    [ValidatePattern('^[0-9a-fA-F]{64}$')][string]$ExpectedSourceSha256,
    [ValidatePattern('^[0-9a-fA-F]{64}$')][string]$ExpectedSqlSha256,
    [ValidatePattern('^[0-9a-fA-F]{16}$')][string]$Nonce
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($AsSql -and (-not $ExpectedSourceSha256 -or -not $ExpectedSqlSha256 -or -not $Nonce)) {
    throw '-AsSql requires the inspected -ExpectedSourceSha256, -ExpectedSqlSha256 and -Nonce.'
}
if (-not $Nonce) { $Nonce = [guid]::NewGuid().ToString('N').Substring(0, 16) }
$table = 'ORA$PTT_BH08_' + $Nonce.ToUpperInvariant()
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$extractor = Join-Path $root 'scripts/Get-BoreholesPackageSource.ps1'
$metadata = & $extractor -Package GS_AI_HUB_FEEDBACK -Unit Body
if ($ExpectedSourceSha256 -and $metadata.SHA256 -ine $ExpectedSourceSha256) {
    throw 'Feedback body changed; inspect it again.'
}
$body = & $extractor -Package GS_AI_HUB_FEEDBACK -Unit Body -AsSource -ExpectedSha256 $metadata.SHA256
$specMetadata = & $extractor -Package GS_AI_HUB_FEEDBACK -Unit Spec
$spec = & $extractor -Package GS_AI_HUB_FEEDBACK -Unit Spec -AsSource -ExpectedSha256 $specMetadata.SHA256
$constant = [regex]::Matches($spec, '(?im)^\s*c_project_key constant varchar2\(30\) := ''geoscience'';[ \t]*\r?$')
if ($constant.Count -ne 1) { throw 'Unexpected project constant.' }
$parts = @($constant[0].Value.Trim())
$names = @('normalized_text', 'short_text', 'idempotency_key', 'source_task_key',
    'build_endpoint_payload', 'upsert_status', 'mark_pending', 'mark_failed', 'queue_latest_feedback')
foreach ($name in $names) {
    $start = [regex]::Matches($body, '(?im)^      (function|procedure) ' + [regex]::Escape($name) + '\b')
    $end = [regex]::Matches($body, '(?im)^      end ' + [regex]::Escape($name) + ';[ \t]*\r?$')
    if ($start.Count -ne 1 -or $end.Count -ne 1 -or $end[0].Index -le $start[0].Index) {
        throw "Ambiguous helper: $name."
    }
    $part = $body.Substring($start[0].Index, $end[0].Index + $end[0].Length - $start[0].Index)
    if ($name -eq 'upsert_status') {
        # A local function is not SQL-callable here. Keep its exact body and
        # invoke it in PL/SQL only when the original insert branch is entered.
        $bridge = @(
            @('(?m)^        l_payload[ \t]+clob;[ \t]*\r?$', "`n        l_fixture_idempotency_key varchar2(255);"),
            @('(?m)^        if sql%rowcount = 0 then[ \t]*\r?$', "`n          l_fixture_idempotency_key := idempotency_key(p_feedback_id);"),
            @('(?m)^            idempotency_key\(p_feedback_id\),[ \t]*\r?$', '            l_fixture_idempotency_key,')
        )
        for ($bridgeIndex = 0; $bridgeIndex -lt $bridge.Count; $bridgeIndex++) {
            $site = [regex]::Matches($part, $bridge[$bridgeIndex][0])
            if ($site.Count -ne 1) { throw "Unexpected idempotency bridge site: $bridgeIndex." }
            $replacement = $bridge[$bridgeIndex][1]
            if ($bridgeIndex -lt 2) { $replacement = $site[0].Value + $replacement }
            $part = $part.Replace($site[0].Value, $replacement)
        }
    }
    $parts += $part
}
$declarations = $parts -join [Environment]::NewLine
$feedbackPattern = '(?im)\bfrom[ \t]+apex_team_feedback\b'
$ledgerPattern = '(?i)\bgs_ai_hub_feedback_forwards\b'
if ([regex]::Matches($declarations, $feedbackPattern).Count -ne 3 -or
    [regex]::Matches($declarations, $ledgerPattern).Count -ne 2) { throw 'Unexpected data dependencies.' }
$fixture = @'
from (
  select 10501 feedback_id, 105 application_id, 'Boreholes fixture' application_name,
         5 page_id, 'Synthetic page' page_name, 'BH08 synthetic feedback' feedback,
         4 feedback_rating, 1920 screen_width, 1080 screen_height,
         'Synthetic agent' http_user_agent, '0' logging_session_id,
         'FIXTURE_USER' created_by, systimestamp - interval '1' minute created_on
    from dual
  union all
  select 10500, 105, 'Boreholes fixture', 5, 'Synthetic page', 'BH08 synthetic feedback',
         4, 1920, 1080, 'Synthetic agent', '0', 'FIXTURE_USER',
         systimestamp - interval '2' minute from dual
  union all
  select 10601, 106, 'Rejected application fixture', 5, 'Synthetic page', 'BH08 synthetic feedback',
         4, 1920, 1080, 'Synthetic agent', '0', 'FIXTURE_USER',
         systimestamp - interval '1' minute from dual
)
'@
$declarations = [regex]::Replace($declarations, $feedbackPattern, $fixture)
$declarations = [regex]::Replace($declarations, $ledgerPattern, $table)

# PTTs prohibit constraints, column defaults and LOB columns. Only the two JSON
# columns use bounded fixture storage; the inner block checks the complete payload.
$source = [IO.File]::ReadAllText($metadata.SourcePath)
$columns = [regex]::Matches($source, '(?ms)create table gs_ai_hub_feedback_forwards \(\s*(.*?)\s*constraint gs_ai_hub_feedback_fwd_pk')
if ($columns.Count -ne 1) { throw 'Expected one canonical ledger column definition.' }
$columnText = $columns[0].Groups[1].Value
$columnText = [regex]::Replace($columnText, "(?i) default (?:'PENDING'|systimestamp)| not null", '').Trim().TrimEnd(',')
if ($columnText -match '(?i)\b(default|constraint|not null)\b') { throw 'Unsupported PTT column definition.' }
foreach ($jsonColumn in @('payload_json', 'response_json')) {
    $jsonColumnPattern = '(?im)\b' + $jsonColumn + '\s+clob\b'
    if ([regex]::Matches($columnText, $jsonColumnPattern).Count -ne 1) { throw "Unexpected JSON column: $jsonColumn." }
    $columnText = [regex]::Replace($columnText, $jsonColumnPattern, "$jsonColumn varchar2(4000 byte)")
}
if ($columnText -match '(?i)\b[bnc]?clob\b|\bblob\b') { throw 'Unexpected remaining PTT LOB column.' }
$ddl = 'create private temporary table ' + $table + ' (' + $columnText + ') on commit drop definition'

# Preserve the reviewed page exception fragment, including its two bind names.
$readme = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'README.md'))
$handlerMatch = [regex]::Matches($readme, '(?s)```plsql\r?\n(exception\r?\n.*?GS_FEEDBACK_QUEUE_FAILED.*?)\r?\n```')
if ($handlerMatch.Count -ne 1) { throw 'Expected one reviewed page diagnostic fragment.' }
$handler = $handlerMatch[0].Groups[1].Value
$template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'queue-assertions.sql.template'))
$inner = $template.Replace('__DECLARATIONS__', $declarations).Replace('__TABLE__', $table).Replace('__PAGE_HANDLER__', $handler)
if ($inner -match '__[A-Z_]+__' -or $inner.Contains("~'")) { throw 'Unsupported inner block delimiter.' }
if ([Text.Encoding]::UTF8.GetByteCount($inner) -gt 32000) { throw 'Inner block exceeds bounded SQL literal size.' }
$code = [regex]::Replace($inner, "(?s)'(?:''|[^'])*'|--[^\r\n]*|/\*.*?\*/", ' ')
if ($code -match '(?i)\b(execute|commit|rollback|create|alter|drop|truncate|grant|delete|merge|apex_web_service|apex_ai|utl_http|autonomous_transaction)\b') {
    throw 'Unexpected mutation or network dependency in inner block.'
}
foreach ($reference in [regex]::Matches($code, '(?i)\b(?:from|join|update|insert\s+into)\s+([a-z][a-z0-9_$#.]*)')) {
    if ($reference.Groups[1].Value -ine 'dual' -and $reference.Groups[1].Value -ine $table) {
        throw 'Non-fixture table dependency.'
    }
}
if ($code -match '@' -or $code.Contains('"')) { throw 'Unexpected remote or quoted dependency.' }
$block = @"
-- Source-derived fixture only; no production tables or package installation.
declare
  c_table constant varchar2(30) := '$table';
  l_created boolean := false;
  l_count number;
  l_original_code number;
  l_cleanup_code number := 0;
  l_stage pls_integer := 0;
begin
  if nvl(sys_context('USERENV','SESSION_USER'),'?') <> 'CODEX'
     or nvl(sys_context('USERENV','CURRENT_SCHEMA'),'?') <> 'CODEX'
     or lower(nvl(sys_context('USERENV','DB_UNIQUE_NAME'),'?')) <> 'tcelkxkd'
     or nvl(apex_application.g_instance,0) <> 0
     or nvl(sys_context('APEX`$SESSION','APP_SESSION'),'0') <> '0' then
    raise_application_error(-20991,'Queue fixture identity/session guard refused.');
  end if;
  if dbms_transaction.local_transaction_id(false) is not null then
    raise_application_error(-20991,'Queue fixture requires a fresh transaction.');
  end if;
  select count(*) into l_count from user_private_temp_tables where table_name = c_table;
  if l_count <> 0 then raise_application_error(-20991,'Nonce table already exists.'); end if;
  l_stage := 1;
  execute immediate q'~$ddl~';
  l_created := true;
  -- Compile extracted static SQL only after this session owns its nonce PTT.
  l_stage := 2;
  execute immediate q'~$inner~' using 106, 5;
  l_stage := 3;
  execute immediate 'drop table ' || dbms_assert.simple_sql_name(c_table);
  l_created := false;
  l_stage := 4;
  select count(*) into l_count from user_private_temp_tables where table_name = c_table;
  if l_count <> 0 then raise_application_error(-20992,'Nonce table cleanup incomplete.'); end if;
  dbms_output.put_line('PASS feedback queue fixture; private table removed; no production forwarding.');
exception
  when others then
    l_original_code := sqlcode;
    if l_stage = 2 and l_original_code = -6550 then
      begin
        dbms_output.put_line(substr(dbms_utility.format_error_stack, 1, 4000));
        dbms_output.put_line(substr(dbms_utility.format_error_backtrace, 1, 1000));
      exception when others then null; -- Diagnostics must not skip owned cleanup.
      end;
    end if;
    if l_created then
      begin
        execute immediate 'drop table ' || dbms_assert.simple_sql_name(c_table);
        l_created := false;
      exception when others then l_cleanup_code := sqlcode;
      end;
    end if;
    raise_application_error(-20993,'Queue fixture failed; originalCode=' || l_original_code
      || '; cleanupCode=' || l_cleanup_code || '; stage=' || l_stage);
end;
"@
if ($block.Contains('&')) { throw 'Literal ampersand would trigger SQLcl substitution.' }
function Get-TextHash([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text)))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
$sqlHash = Get-TextHash $block
if ($ExpectedSqlSha256 -and $sqlHash -ine $ExpectedSqlSha256) {
    throw 'Emitted SQL changed; inspect the source, schema, handler and nonce again.'
}
if ($AsSql) { $block }
else {
    [pscustomobject]@{
        Mode = 'InspectOnly'; SourcePath = $metadata.SourcePath
        SourceSha256 = $metadata.SHA256; SpecSha256 = $specMetadata.SHA256
        PageHandlerSha256 = Get-TextHash $handler
        Nonce = $Nonce.ToUpperInvariant(); PrivateTable = $table
        Routines = $names; FeedbackSelectSubstitutions = 3; LedgerSubstitutions = 2
        RoutineAdaptation = 'upsert_status only: one local key declaration, one original-function assignment inside insert branch, one SQL-expression replacement; other eight routines unchanged'
        PttDifferences = 'Only payload_json and response_json: CLOB to VARCHAR2(4000 BYTE); constraints/defaults omitted; full synthetic payload fit checked before DML'
        PageHandlerBinds = 'APP_ID=106, P10030_PAGE_ID=5; fragment unchanged'
        SqlCharacters = $block.Length; SqlSha256 = $sqlHash
        Coverage = 'Sequential idempotency, status retry, missing-match nonfatal flow, propagated builder error, page diagnostic nonfatal flow'
    }
}
