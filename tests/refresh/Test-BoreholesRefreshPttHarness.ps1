# Offline generator/boundary checks only. No files, database or browser are changed.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$generator = Join-Path $PSScriptRoot 'New-BoreholesRefreshPttHarness.ps1'
$script:checks = 0
function Check([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    $script:checks++
}
function Refuses([scriptblock]$Action, [string]$Message) {
    $refused = $false
    try { & $Action | Out-Null } catch { $refused = $true }
    Check $refused $Message
}

$meta = & $generator -Nonce '0123456789ABCDEF' -ExpectedDbUniqueName 'OFFLINE_TEST'
Check ($meta.Mode -eq 'InspectOnly' -and $meta.Tables.Count -eq 3) 'Default must return inspection metadata only.'
$arguments = @{
    AsSql = $true; ExpectedSourceSha256 = $meta.SourceSha256
    ExpectedDbUniqueName = 'OFFLINE_TEST'; Nonce = $meta.Nonce
}
$sql = & $generator @arguments
Check ($sql -is [string] -and $sql.StartsWith('-- AIDEMODB')) 'SQL must be one in-memory string.'
Check ([regex]::Matches($sql, "execute immediate 'create private temporary table ").Count -eq 3) 'Exactly three private table creations required.'
Check ([regex]::Matches($sql, 'on commit drop definition').Count -eq 3) 'All tables must be transaction scoped.'
Check ($sql -notmatch '(?im)^\s*/\s*$|create or replace|create global|preserve definition') 'No installer, persistent object or script separators.'
Check ($sql.Contains("CURRENT_SCHEMA'), '?') <> 'GEOSCIENCE'") -and $sql.Contains("DB_UNIQUE_NAME'), '?') <> 'OFFLINE_TEST'")) 'Exact schema/database guards required.'
Check ($sql.Contains("nvl(v('APP_USER'), '?') <> 'CODEX'") -and $sql.Contains("find_security_group_id('GEOSCIENCE')")) 'CODEX and workspace guards required.'
Check ($sql.IndexOf('Fixture nonce already exists') -lt $sql.IndexOf("execute immediate 'create")) 'Collision refusal must precede every creation.'
Check ($sql.Contains('if false then raise_application_error(-20995')) 'Default must run fixtures rather than inject failure.'
$failureSql = & $generator @arguments -FailAfterFirstTable
Check ($failureSql.Contains('if true then raise_application_error(-20995')) 'Explicit partial-creation cleanup test must be available.'

$decoded = New-Object System.Text.StringBuilder
$literals = [regex]::Matches($sql, "(?s)l_block := l_block \|\| to_clob\('((?:''|[^'])*)'\);")
Check ($literals.Count -gt 1) 'Source must be split below PL/SQL literal limits.'
foreach ($literal in $literals) {
    $piece = $literal.Groups[1].Value.Replace("''", "'")
    Check ($piece.Length -le 3000) 'A source chunk exceeded its bound.'
    [void]$decoded.Append($piece)
}
$decodedBlock = $decoded.ToString()
# Dot-source only the same offline generator to inspect its pure validation helpers.
. $generator -Nonce $meta.Nonce -ExpectedDbUniqueName 'OFFLINE_TEST' | Out-Null
Check ((Get-TextSha256 $decodedBlock) -eq $meta.LoaderBlockSha256) 'Emitted chunks must reproduce the inspected block exactly.'
Check ($decodedBlock -notmatch '(?i)\bgs_(?:boreholes|borehole_sources|data_refresh_runs|borehole_refresh_api)\b|remote_refresh_json|load_geojson_clob|start_run|apex_web_service') 'No business references, public wrappers or HTTP code.'
foreach ($partName in @('validate_limit', 'clean_text', 'clean_number', 'clean_date', 'fail_run', 'apply_geojson')) {
    $original = Get-LoaderSubprogram $body $partName
    foreach ($table in $map.Keys) { $original = [regex]::Replace($original, '(?i)\b' + $table + '\b', $map[$table]) }
    Check ($decodedBlock.Contains($original)) "Actual subprogram changed beyond table remapping: $partName."
}
Check ($decodedBlock.Contains('mid-batch insert failure') -and $decodedBlock.Contains('earlier update rolled back') -and
    $decodedBlock.Contains('retained diagnostics') -and $decodedBlock.Contains('unrelated caller work')) 'Core rollback assertions missing.'

Refuses { & $generator -AsSql -ExpectedSourceSha256 $meta.SourceSha256 } 'Missing database identity must fail.'
Refuses { & $generator -AsSql -ExpectedDbUniqueName 'OFFLINE_TEST' } 'Missing source hash must fail.'
Refuses { & $generator -ExpectedSourceSha256 ('0' * 64) } 'Stale source must fail.'
Refuses { & $generator -Nonce "ABC'; drop table x;--" } 'Invalid nonce must fail.'
Refuses { & $generator -ExpectedDbUniqueName "x';--" } 'Invalid database literal must fail.'
foreach ($forbidden in @(
    'select count(*) into l_count from gs_boreholes;',
    'select count(*) into l_count from unrelated_table;',
    'gs_borehole_refresh_api.remote_refresh_json();',
    'apex_web_service.make_rest_request();',
    'dbms_cloud.send_request();',
    'commit;', 'rollback;', 'rollback to unrelated_savepoint;',
    "execute immediate 'begin null; end;';", 'grant select on x to y;'
)) {
    Refuses { Assert-IsolatedLoaderBlock ($decodedBlock + "`n" + $forbidden) @($meta.Tables) } "Forbidden addition accepted: $forbidden"
}
$oldFixture = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'fixture-regression.sql'))
Check ($oldFixture.Contains("if user <> 'BOREHOLES_TEST' or sys_context('USERENV', 'CURRENT_SCHEMA') <> 'BOREHOLES_TEST' then")) 'Original isolated-owner guard must remain intact.'
"PASS: $script:checks offline generator, extraction and refusal checks. No Oracle execution performed."
