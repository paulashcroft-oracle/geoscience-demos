# Emits an anonymous, read-only probe built from current canonical helper source.
# Does not connect to Oracle, create files, or alter the package.
[CmdletBinding()]
param(
    [string]$SourcePath = (Join-Path $PSScriptRoot '..\..\database\009_create_boreholes_refresh_agent_api.sql')
)
$ErrorActionPreference = 'Stop'
$source = Get-Content -LiteralPath $SourcePath -Raw
$bodyMatches = [regex]::Matches($source, '(?ms)^create or replace package body gs_borehole_agent_api as\r?\n(?<body>.*?)^end gs_borehole_agent_api;\r?$')
if ($bodyMatches.Count -ne 1) { throw 'Expected exactly one canonical agent package body.' }
$body = $bodyMatches[0].Groups['body'].Value
function Get-CanonicalDeclaration([string]$Pattern, [string]$Name) {
    $matches = [regex]::Matches($body, $Pattern)
    if ($matches.Count -ne 1) { throw "Expected exactly one canonical declaration: $Name" }
    return $matches[0].Value.TrimEnd()
}
$declarations = @(
    Get-CanonicalDeclaration '(?m)^  type t_evidence is record \([^\r\n]+\);\r?$' 't_evidence'
    foreach ($name in @('append_text', 'append_line', 'append_clob', 'append_escaped')) {
        Get-CanonicalDeclaration "(?ms)^  procedure $name\b.*?^  end;\r?$" $name
    }
    Get-CanonicalDeclaration '(?ms)^  function render_answer\b.*?^  end;\r?$' 'render_answer'
)
$assertions = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'unicode-helper-assertions.sql') -Raw
$sourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
@(
    '-- Current D009 helper source SHA256: ' + $sourceHash
    '-- Local CLOB/APEX_ESCAPE operations only; no provider, table access, or installed-package changes.'
    'declare'
    $declarations
    $assertions.TrimEnd()
    'begin'
    '  run_unicode_helper_probes;'
    'end;'
    '/'
) -join [Environment]::NewLine
