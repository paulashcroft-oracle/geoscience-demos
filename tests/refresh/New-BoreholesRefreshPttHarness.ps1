<#
.SYNOPSIS
Build a source-derived, isolated loader test; never connect to or execute SQL.
.DESCRIPTION
Default output is inspection metadata. -AsSql requires the inspected body hash
and the DB_UNIQUE_NAME observed in the owning GEOSCIENCE SQL Workshop session.
The generated single anonymous block uses three nonce-named private temporary
tables. It extracts only loader dependencies, with fixed table-name remapping.
No installed package, HTTP, sequence, business table or persistent object is used.
#>
[CmdletBinding()]
param(
    [switch]$AsSql,
    [ValidatePattern('^[0-9a-fA-F]{64}$')][string]$ExpectedSourceSha256,
    [ValidatePattern('^[A-Za-z0-9_#-]{1,128}$')][string]$ExpectedDbUniqueName,
    [ValidatePattern('^[0-9A-F]{16}$')][string]$Nonce = ([guid]::NewGuid().ToString('N').Substring(0, 16).ToUpperInvariant()),
    [switch]$FailAfterFirstTable
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($AsSql -and (-not $ExpectedSourceSha256 -or -not $ExpectedDbUniqueName)) {
    throw '-AsSql requires -ExpectedSourceSha256 and the observed -ExpectedDbUniqueName.'
}

function Get-TextSha256([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text)))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Get-LoaderSubprogram([string]$Body, [string]$Name) {
    $start = [regex]::Matches($Body, '(?im)^  (?:function|procedure) ' + [regex]::Escape($Name) + '\b')
    $end = [regex]::Matches($Body, '(?im)^  end ' + [regex]::Escape($Name) + ';[ \t]*\r?$')
    if ($start.Count -ne 1 -or $end.Count -ne 1 -or $end[0].Index -le $start[0].Index) {
        throw "Ambiguous or missing loader subprogram: $Name."
    }
    $Body.Substring($start[0].Index, $end[0].Index + $end[0].Length - $start[0].Index)
}

function Assert-IsolatedLoaderBlock([string]$Block, [string[]]$TableNames) {
    # This intentionally accepts the current simple SQL lexical forms only.
    # Refuse new q-quoting/quoted identifiers rather than guessing their boundaries.
    if ($Block -match '(?i)\bq\x27') { throw 'Unsupported q-quoted source in loader block.' }
    if ($Block -match '(?i)\b(?:GS_BOREHOLES|GS_BOREHOLE_SOURCES|GS_DATA_REFRESH_RUNS|GS_BOREHOLE_REFRESH_API)\b') {
        throw 'Original business-table or installed-package reference remains.'
    }
    $code = [regex]::Replace($Block, "(?s)'(?:''|[^'])*'|--[^\r\n]*|/\*.*?\*/", ' ')
    if ($code.Contains('"')) { throw 'Quoted SQL identifiers require explicit harness review.' }
    if ($code -match '(?i)\b(gs_(?!borehole_batch\b)[a-z0-9_$#]*|apex_web_service|utl_[a-z0-9_]+|apex_ai|execute|commit|autonomous_transaction|dbms_sql|dbms_scheduler|dbms_job|dbms_pipe|dbms_lock|create|alter|drop|truncate|grant|merge|call)\b') {
        throw "Forbidden database object, execution or external call in loader block: $($Matches[0])."
    }
    if ($code -match '(?i)\brollback\s*;' -or $code -match '@') { throw 'Only named savepoint rollback and local tables are allowed.' }
    foreach ($qualified in [regex]::Matches($code, '(?i)\b([a-z][a-z0-9_$#]*)\s*\.\s*[a-z_]')) {
        if ($qualified.Groups[1].Value.ToLowerInvariant() -cnotin @('apex_json', 'dbms_lob', 'dbms_output', 'l_value', 'l_seen_refs')) {
            throw "Unexpected qualified dependency: $($qualified.Groups[1].Value)."
        }
    }
    foreach ($savepoint in [regex]::Matches($code, '(?i)\b(?:savepoint|rollback\s+to)\s+([a-z0-9_$#]+)')) {
        if ($savepoint.Groups[1].Value -ine 'gs_borehole_batch') { throw 'Unexpected savepoint scope.' }
    }
    $references = [regex]::Matches($code, '(?i)\b(?:from|join|insert\s+into|update|delete\s+from)\s+([a-z0-9_$#.]+)')
    foreach ($reference in $references) {
        if ($reference.Groups[1].Value.ToUpperInvariant() -cnotin $TableNames) {
            throw "Unexpected table reference: $($reference.Groups[1].Value)."
        }
    }
    foreach ($name in $TableNames) {
        if ($code -notmatch ('(?i)\b' + [regex]::Escape($name) + '\b')) { throw "Missing fixture table: $name." }
    }
}

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$extractor = Join-Path $root 'scripts/Get-BoreholesPackageSource.ps1'
$metadata = & $extractor -Package GS_BOREHOLE_REFRESH_API -Unit Body
if ($ExpectedSourceSha256 -and $metadata.SHA256 -ine $ExpectedSourceSha256) { throw 'Refresh package body hash changed; inspect it again.' }
$body = & $extractor -Package GS_BOREHOLE_REFRESH_API -Unit Body -AsSource -ExpectedSha256 $metadata.SHA256
$constant = [regex]::Matches($body, '(?im)^  c_max_response_chars constant pls_integer := [0-9]+;[ \t]*\r?$')
if ($constant.Count -ne 1) { throw 'Ambiguous response-size constant.' }
$parts = @($constant[0].Value)
foreach ($name in @('validate_limit', 'clean_text', 'clean_number', 'clean_date', 'fail_run', 'apply_geojson')) {
    $parts += Get-LoaderSubprogram $body $name
}
$declarations = $parts -join "`n`n"
$map = [ordered]@{
    GS_BOREHOLES = 'ORA$PTT_BH_' + $Nonce + '_B'
    GS_BOREHOLE_SOURCES = 'ORA$PTT_BH_' + $Nonce + '_S'
    GS_DATA_REFRESH_RUNS = 'ORA$PTT_BH_' + $Nonce + '_R'
}
foreach ($name in $map.Keys) {
    if ($declarations -notmatch ('(?i)\b' + $name + '\b')) { throw "Missing expected source table: $name." }
    $declarations = [regex]::Replace($declarations, '(?i)\b' + $name + '\b', $map[$name])
}
$template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'ptt-loader-fixtures.sql.template'))
$inner = $template.Replace('__DECLARATIONS__', $declarations).
    Replace('__BOREHOLES__', $map.GS_BOREHOLES).
    Replace('__SOURCES__', $map.GS_BOREHOLE_SOURCES).
    Replace('__RUNS__', $map.GS_DATA_REFRESH_RUNS)
if ($inner -match '__[A-Z_]+__') { throw 'Unresolved fixture template placeholder.' }
Assert-IsolatedLoaderBlock $inner @($map.Values)
$innerHash = Get-TextSha256 $inner
if (-not $AsSql) {
    [pscustomobject]@{
        Mode = 'InspectOnly'; SourcePath = $metadata.SourcePath; SourceSha256 = $metadata.SHA256
        LoaderBlockSha256 = $innerHash; LoaderCharacters = $inner.Length; Nonce = $Nonce
        Tables = @($map.Values); TargetSchema = 'GEOSCIENCE'; ExpectedDbUniqueName = $ExpectedDbUniqueName
        FailAfterFirstTable = [bool]$FailAfterFirstTable
        Coverage = 'Extracted apply_geojson/fail_run only; no public wrapper, HTTP, identity/default or constraint coverage'
    }
    return
}

# Small escaped literals avoid PL/SQL literal limits even if the source grows.
$chunks = for ($offset = 0; $offset -lt $inner.Length; $offset += 3000) {
    $chunk = $inner.Substring($offset, [Math]::Min(3000, $inner.Length - $offset)).Replace("'", "''")
    "  l_block := l_block || to_clob('$chunk');"
}
$outer = @'
-- AIDEMODB / GEOSCIENCE: synthetic PTT loader regression, single SQL Commands call.
-- Source body SHA256: __SOURCE_HASH__; inner block SHA256: __INNER_HASH__.
declare
  type t_names is table of varchar2(30) index by pls_integer;
  type t_flags is table of boolean index by pls_integer;
  l_names t_names;
  l_created t_flags;
  l_block clob;
  l_count number;
  l_error varchar2(2000);
  l_cleanup_error varchar2(2000);
  procedure cleanup is
    l_remaining number;
    l_failures varchar2(1800);
  begin
    for i in reverse 1 .. 3 loop
      if l_created.exists(i) and l_created(i) then
        begin
          if l_names(i) not in ('__B__', '__S__', '__R__') then
            raise_application_error(-20994, 'Cleanup refused unknown object.');
          end if;
          select count(*) into l_remaining from user_private_temp_tables where table_name = l_names(i);
          if l_remaining = 1 then execute immediate 'drop table ' || l_names(i); end if;
          select count(*) into l_remaining from user_private_temp_tables where table_name = l_names(i);
          if l_remaining <> 0 then raise_application_error(-20994, 'PTT cleanup verification failed.'); end if;
          l_created(i) := false;
        exception when others then
          l_failures := substr(l_failures || ' ' || l_names(i) || ': ' || sqlerrm, 1, 1800);
        end;
      end if;
    end loop;
    if l_failures is not null then raise_application_error(-20994, l_failures); end if;
  end cleanup;
begin
  -- All checks precede CREATE; do not change these to run in another target.
  if nvl(sys_context('USERENV', 'CURRENT_SCHEMA'), '?') <> 'GEOSCIENCE'
     or nvl(sys_context('USERENV', 'DB_UNIQUE_NAME'), '?') <> '__DB_UNIQUE__'
     or nvl(apex_custom_auth.get_security_group_id, -1) <> nvl(apex_util.find_security_group_id('GEOSCIENCE'), -2)
     or nvl(v('APP_USER'), '?') <> 'CODEX' then
    raise_application_error(-20991, 'Requires the inspected database and CODEX GEOSCIENCE SQL Workshop context.');
  end if;
  l_names(1) := '__B__'; l_names(2) := '__S__'; l_names(3) := '__R__';
  for i in 1 .. 3 loop
    l_created(i) := false;
    if not regexp_like(l_names(i), '^ORA[$]PTT_BH_[0-9A-F]{16}_[BSR]$', 'c') then
      raise_application_error(-20991, 'Invalid fixture name.');
    end if;
    select count(*) into l_count from user_private_temp_tables where table_name = l_names(i);
    if l_count <> 0 then raise_application_error(-20991, 'Fixture nonce already exists; no object touched.'); end if;
  end loop;
  execute immediate 'create private temporary table __B__ (
    source_id number, borehole_ref varchar2(100 char), borehole_name varchar2(240 char),
    state_code varchar2(20 char), state_name varchar2(120 char), region_name varchar2(160 char),
    latitude number, longitude number, depth_metres number, drilled_year number,
    commodity_group varchar2(160 char), status_code varchar2(40 char), external_id varchar2(120 char),
    identifier_uri varchar2(1000 char), purpose varchar2(240 char), operator_name varchar2(240 char),
    driller_name varchar2(240 char), drill_start_date date, drill_end_date date, elevation_m number,
    positional_accuracy varchar2(240 char), data_custodian varchar2(240 char), geological_provinces varchar2(1000 char),
    metadata_uri varchar2(1000 char), borehole_report_uri varchar2(1000 char), qa_status varchar2(120 char),
    last_refresh_run_id number, source_updated_at timestamp with local time zone,
    updated_at timestamp with local time zone) on commit drop definition';
  l_created(1) := true;
  if __FAIL_FIRST__ then raise_application_error(-20995, 'Intentional test of cleanup after first PTT creation.'); end if;
  execute immediate 'create private temporary table __S__ (
    source_id number, last_refresh_at timestamp with local time zone,
    source_status varchar2(30 char), updated_at timestamp with local time zone) on commit drop definition';
  l_created(2) := true;
  execute immediate 'create private temporary table __R__ (
    refresh_run_id number, source_id number, status_code varchar2(30 char),
    rows_loaded number, rows_rejected number, started_at timestamp with local time zone,
    finished_at timestamp with local time zone, response_bytes number, message varchar2(2000 char)) on commit drop definition';
  l_created(3) := true;
__CHUNKS__
  execute immediate l_block;
  cleanup;
  select count(*) into l_count from user_private_temp_tables where table_name in ('__B__', '__S__', '__R__');
  if l_count <> 0 then raise_application_error(-20994, 'Fixture objects remain.'); end if;
  dbms_output.put_line('PASS: extracted loader fixtures and all three PTTs removed; source __SOURCE_HASH__.');
exception
  when others then
    l_error := substr(sqlerrm, 1, 1000);
    begin cleanup; exception when others then l_cleanup_error := substr(sqlerrm, 1, 1000); end;
    if l_cleanup_error is not null then
      raise_application_error(-20994, substr(l_error || ' CLEANUP FAILED: ' || l_cleanup_error, 1, 2000));
    end if;
    dbms_output.put_line('FAIL: ' || l_error || '; cleanup verified for every PTT created by this call.');
    raise;
end;
'@
$outer = $outer.Replace('__SOURCE_HASH__', $metadata.SHA256).Replace('__INNER_HASH__', $innerHash).
    Replace('__DB_UNIQUE__', $ExpectedDbUniqueName).
    Replace('__B__', $map.GS_BOREHOLES).Replace('__S__', $map.GS_BOREHOLE_SOURCES).Replace('__R__', $map.GS_DATA_REFRESH_RUNS).
    Replace('__FAIL_FIRST__', $(if ($FailAfterFirstTable) { 'true' } else { 'false' })).
    Replace('__CHUNKS__', ($chunks -join "`n"))
if ($outer -match '__[A-Z_]+__') { throw 'Unresolved outer template placeholder.' }
$outer
