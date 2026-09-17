<#
.SYNOPSIS
Inspect or return exactly one allowlisted package source unit. Never executes SQL.
.DESCRIPTION
With no arguments, reports metadata for all eight specification/body units.
With -Package, reports that package's selected -Unit (Body by default).
-AsSource explicitly returns only the selected CREATE OR REPLACE statement as
one in-memory string, without a SQLcl slash, installer wrapper or trailing newline.
No database, clipboard, network, file-write or process-launch actions occur.

SHA256 and Utf8Bytes describe exactly that string encoded as UTF-8 without BOM.
Characters is its .NET UTF-16 length; original internal line endings are retained.
An optional -ExpectedSha256 rejects source changed since its inspection.
Inspection does not establish current live equality or authorize deployment.
.EXAMPLE
& .\scripts\Get-BoreholesPackageSource.ps1
.EXAMPLE
& .\scripts\Get-BoreholesPackageSource.ps1 -Package GS_BOREHOLE_AGENT_API
.EXAMPLE
$sql = & .\scripts\Get-BoreholesPackageSource.ps1 -Package GS_BOREHOLE_AGENT_API -Unit Body -AsSource
#>
[CmdletBinding()]
param(
    [ValidateSet('GS_AI_HUB_FEEDBACK', 'GS_BOREHOLE_REFRESH_API', 'GS_BOREHOLE_AGENT_API', 'GS_BOREHOLE_PAGE_API')]
    [string]$Package,

    [ValidateSet('Spec', 'Body')]
    [string]$Unit = 'Body',

    [switch]$AsSource,

    [ValidatePattern('^[0-9a-fA-F]{64}$')]
    [string]$ExpectedSha256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (($AsSource -or $ExpectedSha256 -or $PSBoundParameters.ContainsKey('Unit')) -and -not $Package) {
    throw 'Select exactly one -Package before selecting a unit, returning source or checking its expected hash.'
}

$sources = [ordered]@{
    GS_AI_HUB_FEEDBACK = '006_create_geoscience_feedback_queue.sql'
    GS_BOREHOLE_REFRESH_API = '009_create_boreholes_refresh_agent_api.sql'
    GS_BOREHOLE_AGENT_API = '009_create_boreholes_refresh_agent_api.sql'
    GS_BOREHOLE_PAGE_API = '010_create_boreholes_page_api.sql'
}
$databaseRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'database'
$names = if ($Package) { @($Package.ToUpperInvariant()) } else { @($sources.Keys) }
$units = if ($Package) { @($Unit) } else { @('Spec', 'Body') }
$encoding = New-Object System.Text.UTF8Encoding($false)

foreach ($name in $names) {
    $path = Join-Path $databaseRoot $sources[$name]
    $sourceText = [System.IO.File]::ReadAllText($path)
    foreach ($kind in $units) {
        $bodyToken = if ($kind -eq 'Body') { 'body[ \t]+' } else { '' }
        $headerPattern = '(?im)^[ \t]*(?<header>create[ \t]+or[ \t]+replace[ \t]+package[ \t]+' +
            $bodyToken + [regex]::Escape($name) + '\b[^\r\n]*)'
        $headers = [regex]::Matches($sourceText, $headerPattern)
        if ($headers.Count -ne 1) { throw "Expected exactly one $kind header for $name in $path; found $($headers.Count)." }

        $start = $headers[0].Groups['header'].Index
        $tail = $sourceText.Substring($start)
        $endPattern = '(?im)^[ \t]*end[ \t]+' + [regex]::Escape($name) + ';[ \t]*(?=\r?$)'
        $ends = [regex]::Matches($tail, $endPattern)
        # The specification's tail also contains its body. Select the first named
        # END, then verify the surrounding statement boundary below.
        if ($ends.Count -lt 1) { throw "Missing named END for $name $kind." }
        $length = $ends[0].Index + $ends[0].Length
        $text = $tail.Substring(0, $length).TrimEnd([char[]]" `t")
        if ([regex]::Matches($text, '(?im)^[ \t]*create[ \t]+or[ \t]+replace[ \t]+package\b').Count -ne 1) {
            throw 'Extraction crossed another package header; refusing to return combined source.'
        }
        if ([regex]::IsMatch($text, '(?m)^[ \t]*/[ \t]*\r?$')) {
            throw 'Extraction contains a SQLcl statement separator; refusing combined source.'
        }

        $before = $sourceText.Substring(0, $start)
        $after = $sourceText.Substring($start + $length)
        $framing = 'Standalone'
        if ($name -eq 'GS_AI_HUB_FEEDBACK') {
            # D006 wraps the spec in q'[...]' and the body in q'~...~'.
            # Validate both wrapper edges, but return neither EXECUTE IMMEDIATE
            # nor the surrounding foundation block and its COMMIT.
            $wrapper = [regex]::Match($before, "(?i)execute[ \t]+immediate[ \t]+q'(?<open>\[|~)\s*\z")
            if (-not $wrapper.Success) { throw 'Unrecognized D006 q-quoted opening wrapper.' }
            $closing = if ($wrapper.Groups['open'].Value -eq '[') { ']' } else { '~' }
            if (-not [regex]::IsMatch($after, '^\s*' + [regex]::Escape($closing) + "';")) {
                throw 'Unrecognized D006 q-quoted closing wrapper.'
            }
            $framing = 'Unwrapped q-quoted statement'
        } elseif (-not [regex]::IsMatch($after, '^\s*/[ \t]*(\r?\n|\z)')) {
            throw 'Missing standalone SQLcl boundary after named END; refusing ambiguous extraction.'
        }

        $bytes = $encoding.GetBytes($text)
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try { $digest = ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant() }
        finally { $sha.Dispose() }
        if ($ExpectedSha256 -and $digest -ine $ExpectedSha256) { throw 'Selected source hash differs from -ExpectedSha256; inspect and reconcile it again.' }

        if ($AsSource) { $text }
        else {
            [pscustomobject]@{
                Mode = 'InspectOnly'
                Package = $name
                Unit = $kind
                SourcePath = [System.IO.Path]::GetFullPath($path)
                StartLine = ([regex]::Matches($sourceText.Substring(0, $start), '\n').Count + 1)
                Characters = $text.Length
                Utf8Bytes = $bytes.Length
                SHA256 = $digest
                Framing = $framing
            }
        }
    }
}
