# readme-generate.ps1 — point d'entrée
# PowerShell pur, zéro dépendance, structure immuable, sections par présence.
# Usage : .\readme-generate.ps1 [-Lang en|fr]

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost','')]
param(
    [ValidateSet('en','fr')]
    [string]$Lang = 'en'
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'utils.ps1')
. (Join-Path $PSScriptRoot 'helpers.ps1')
. (Join-Path $PSScriptRoot 'i18n.ps1')
. (Join-Path $PSScriptRoot 'generateInventory.ps1')
. (Join-Path $PSScriptRoot 'generateSections.ps1')

$inv = Get-RBInventory
$md = Generate-RBAllSections -Inv $inv -Lang $Lang

$md = [regex]::Replace($md, '\n{3,}', "`n`n")
if (-not $md.EndsWith("`n")) { $md += "`n" }

$outDir = Join-Path $Root 'docs'
if (-not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}
$suffix = if ($Lang -eq 'en') { '' } else { ".${Lang}" }
$outPath = Join-Path $outDir "README${suffix}.md"
Set-Content -LiteralPath $outPath -Value $md -Encoding utf8
Write-Host "README${suffix}.md -> $outPath"
