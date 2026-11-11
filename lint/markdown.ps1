[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
# lint/lint-md.ps1 - verification et correction automatique des fichiers Markdown
# Usage : pwsh -File lint/lint-md.ps1 [-Path <dir|file>] [-Fix]

[CmdletBinding()]
param(
    [string]$Path,
    [switch]$Fix
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $Path) { $Path = $root }

$files = if (Test-Path $Path -PathType Container) {
    Get-ChildItem -Path $Path -Recurse -Filter *.md
} else {
    @(Get-Item -Path $Path)
}

$issuesFound = $false
foreach ($f in $files) {
    $content = Get-Content -LiteralPath $f.FullName -Raw
    $original = $content

    # MD022 : headings entoures de lignes vides
    $content = [regex]::Replace($content, '(?<!\n)\n(#{1,6}\s)', "`n`n`$1")
    $content = [regex]::Replace($content, '(#{1,6}\s[^\n]+)\n(?!\n)', "`$1`n`n")

    # MD032 : listes entourees de lignes vides
    $content = [regex]::Replace($content, '(?<!\n)\n(- |\* |\d+\. )', "`n`n`$1")
    $content = [regex]::Replace($content, '(- |\* |\d+\. [^\n]+)\n(?!\n|- |\* |\d+\. )', "`$1`n`n")

    # MD060 : tableaux avec espaces autour des pipes (separateurs)
    $content = [regex]::Replace($content, '(?m)^\|[-\s|]+\|$', { param($m)
        $cols = $m.Value -split '\|'
        $out = ''
        for ($i = 1; $i -lt $cols.Count - 1; $i++) {
            $out += '| --- '
        }
        $out += '|'
        return $out
    })

    if ($Fix -and $content -ne $original) {
        Set-Content -LiteralPath $f.FullName -Value $content -Encoding utf8
        Write-Host "[FIXED] $($f.FullName)" -ForegroundColor Green
    } elseif ($content -ne $original) {
        Write-Host "[ISSUE] $($f.FullName)" -ForegroundColor Yellow
        $issuesFound = $true
    } else {
        Write-Host "[OK] $($f.FullName)" -ForegroundColor Green
    }
}

if ($issuesFound -and -not $Fix) { exit 1 } else { exit 0 }
