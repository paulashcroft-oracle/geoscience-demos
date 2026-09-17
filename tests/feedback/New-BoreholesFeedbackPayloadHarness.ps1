<#
.SYNOPSIS
Inspect or emit a source-derived, read-only anonymous feedback payload test.
.DESCRIPTION
Never connects to Oracle or executes SQL. The selected package helpers are
extracted exactly; only the payload SELECT's table is replaced by two inline
fixtures. Existing APEX_TEAM_FEEDBACK column types remain metadata anchors.
No queue routines, business-table reads/writes, provider calls or DDL are emitted.
#>
[CmdletBinding()]
param(
    [switch]$AsSql,
    [ValidatePattern('^[0-9a-fA-F]{64}$')][string]$ExpectedSourceSha256
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($AsSql -and -not $ExpectedSourceSha256) {
    throw '-AsSql requires the inspected -ExpectedSourceSha256.'
}
$extractor = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'scripts/Get-BoreholesPackageSource.ps1'
$metadata = & $extractor -Package GS_AI_HUB_FEEDBACK -Unit Body
if ($ExpectedSourceSha256 -and $metadata.SHA256 -ine $ExpectedSourceSha256) {
    throw 'Feedback body changed; inspect it again.'
}
$body = & $extractor -Package GS_AI_HUB_FEEDBACK -Unit Body -AsSource -ExpectedSha256 $metadata.SHA256
$spec = & $extractor -Package GS_AI_HUB_FEEDBACK -Unit Spec -AsSource
$constant = [regex]::Matches($spec, '(?im)^\s*c_project_key constant varchar2\(30\) := ''geoscience'';[ \t]*\r?$')
if ($constant.Count -ne 1) { throw 'Unexpected project constant.' }
$parts = @($constant[0].Value.Trim())
foreach ($name in @('normalized_text', 'short_text', 'idempotency_key', 'source_task_key', 'build_endpoint_payload')) {
    $start = [regex]::Matches($body, '(?im)^      function ' + [regex]::Escape($name) + '\b')
    $end = [regex]::Matches($body, '(?im)^      end ' + [regex]::Escape($name) + ';[ \t]*\r?$')
    if ($start.Count -ne 1 -or $end.Count -ne 1 -or $end[0].Index -le $start[0].Index) {
        throw "Ambiguous helper: $name."
    }
    $parts += $body.Substring($start[0].Index, $end[0].Index + $end[0].Length - $start[0].Index)
}
$declarations = $parts -join "`n`n"
$tablePattern = '(?im)\bfrom[ \t]+apex_team_feedback\b'
if ([regex]::Matches($declarations, $tablePattern).Count -ne 1) { throw 'Expected exactly one payload source SELECT.' }
$fixture = @'
from (
  select 10401 feedback_id, 104 application_id, 'Geoscience Demos' application_name,
         2 page_id, 'Explore Data' page_name, 'Saved "quoted" <feedback> ' || chr(38) || ' text.' feedback,
         4 feedback_rating, 1920 screen_width, 1080 screen_height,
         'Synthetic test agent' http_user_agent, '12345' logging_session_id,
         'FIXTURE_USER' created_by,
         to_timestamp_tz('2026-09-17 01:02:03 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM') created_on
    from dual
  union all
  select 10501, 105, 'Boreholes Demo', 5, 'AI Data Assistant',
         'Saved "quoted" <feedback> ' || chr(38) || ' text.', 4, 1920, 1080,
         'Synthetic test agent', '12345', 'FIXTURE_USER',
         to_timestamp_tz('2026-09-17 01:02:03 +00:00', 'YYYY-MM-DD HH24:MI:SS TZH:TZM')
    from dual
)
'@
$declarations = [regex]::Replace($declarations, $tablePattern, $fixture)
$template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'payload-assertions.sql.template'))
$block = $template.Replace('__DECLARATIONS__', $declarations)
if ($block -match '__[A-Z_]+__' -or $block -match '(?i)\bq\x27') { throw 'Unsupported fixture source.' }
if ($block.Contains('&')) { throw 'Literal ampersand would trigger SQLcl substitution.' }
$code = [regex]::Replace($block, "(?s)'(?:''|[^'])*'|--[^\r\n]*|/\*.*?\*/", ' ')
if ($code -match '(?i)\b(insert|update|delete|merge|execute|commit|rollback|create|alter|drop|truncate|grant|apex_web_service|apex_ai|upsert_status|mark_pending|mark_forwarded|mark_failed|queue_latest_feedback)\b') {
    throw "Mutation, network or queue dependency: $($Matches[0])."
}
foreach ($reference in [regex]::Matches($code, '(?i)\b(?:from|join)\s+([a-z][a-z0-9_$#.]*)')) {
    if ($reference.Groups[1].Value -ine 'dual') { throw 'Non-fixture table read.' }
}
if ($code -match '@' -or $code.Contains('"')) { throw 'Unexpected remote or quoted dependency.' }
if ($AsSql) { $block }
else {
    [pscustomobject]@{
        Mode = 'InspectOnly'; SourcePath = $metadata.SourcePath
        SourceSha256 = $metadata.SHA256; Characters = $block.Length
        FixtureRows = 2; ExpectedAssertions = 16
        Coverage = '104/105 payload mapping, historical provenance, returned CLOB lifetime, missing-row output ownership; no queue DML or forwarding'
    }
}
