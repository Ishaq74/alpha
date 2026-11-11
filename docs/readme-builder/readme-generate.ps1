# readme-generate.ps1 - point d'entrée du readme-builder
# PowerShell pur, zéro dépendance, structure immuable, sections par présence.
# Usage : .\readme-generate.ps1 [-Root <path>] [-Lang en|fr|...] [-DryRun] [-Yes] [-LogFile <path>]

[CmdletBinding()]
param(
    [string]$Root,
    [ValidateSet('en','fr','es','ar')]
    [string]$Lang = 'en',
    [string]$OutDir,
    [int]$MaxDepth = 3,
    [switch]$DryRun,
    [switch]$Yes,
    [string]$LogFile
)

$ErrorActionPreference = 'Stop'

# Socle partagé
. (Join-Path $PSScriptRoot '..\..\lib\state.ps1')
$State = @{
    Name         = ''
    Dir          = ''
    GitLocal     = $false
    GitHub       = $false
    GitHubUrl    = ''
    VsCode       = $false
    DryRun       = $DryRun.IsPresent
    AssumeYes    = $Yes.IsPresent
    ForceGit     = $false
    ForceGitHub  = $false
    ForcePublic  = $false
    ForceVsCode  = $false
    ExtensionsDir = ''
    LogFile      = $LogFile
}
. (Join-Path $PSScriptRoot '..\..\lib\logging.ps1')
. (Join-Path $PSScriptRoot '..\..\lib\helpers.ps1')
. (Join-Path $PSScriptRoot '..\..\lib\readme.ps1')

# Racine cible
if (-not $Root) { $Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }
Set-RBRoot -Path $Root
Set-RBI18nDir -Path (Join-Path $PSScriptRoot 'i18n')

if (-not (Test-RBI18nLoaded -Lang $Lang)) {
    Die "Fichier i18n introuvable pour la langue '$Lang' : $(Join-Path (Join-Path $PSScriptRoot 'i18n') "$Lang.json")"
}

if ($State.LogFile) {
    if (Test-Path $State.LogFile) { Clear-Content $State.LogFile }
    Write-Info "Journal : $($State.LogFile)"
}

Write-Info "Démarrage du readme-builder sur $Root"

$inv = Get-RBInventory
$md = Generate-RBAllSections -Inv $inv -Lang $Lang -MaxDepth $MaxDepth

$md = [regex]::Replace($md, '\n{3,}', "`n`n")
if (-not $md.EndsWith("`n")) { $md += "`n" }

if (-not $OutDir) { $OutDir = $Root }
$outDir = $OutDir
Invoke-Run { if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null } }
$suffix = if ($Lang -eq 'en') { '' } else { ".${Lang}" }
$outPath = Join-Path $outDir "README${suffix}.md"
Invoke-Run { Set-Content -LiteralPath $outPath -Value $md -Encoding utf8 }
Write-Ok "README${suffix}.md -> $outPath"
