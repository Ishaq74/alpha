# utils.ps1 — socle générique du readme-builder
# Aucun chemin figé : tout part de la racine du repo.

$ErrorActionPreference = 'Stop'

$BuilderDir = $PSScriptRoot
$Root = Split-Path -Parent (Split-Path -Parent $BuilderDir)

function Read-RBFile {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        return Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
    }
    return ''
}

function Get-RBTree {
    param(
        [string]$Dir,
        [int]$Depth = 0,
        [int]$MaxDepth = 3
    )
    if ($Depth -gt $MaxDepth) { return '' }
    if (-not (Test-Path -LiteralPath $Dir)) { return '' }
    $out = ''
    Get-ChildItem -LiteralPath $Dir -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch '^\.' -and $_.Name -ne 'node_modules' -and $_.Name -ne 'dist'
    } | ForEach-Object {
        $indent = '  ' * $Depth
        if ($_.PSIsContainer) {
            $out += "$indent$($_.Name)/`n"
            $out += Get-RBTree -Dir $_.FullName -Depth ($Depth + 1) -MaxDepth $MaxDepth
        } else {
            $out += "$indent$($_.Name)`n"
        }
    }
    return $out
}

function Get-RBTopLevel {
    if (-not (Test-Path -LiteralPath $Root)) { return @() }
    return @(Get-ChildItem -LiteralPath $Root -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch '^\.'
    } | ForEach-Object { $_.Name })
}

function Test-RBItem {
    param([string]$Name)
    return (Test-Path -LiteralPath (Join-Path $Root $Name))
}

function Get-RBChildNames {
    param([string]$Name)
    $p = Join-Path $Root $Name
    if (-not (Test-Path -LiteralPath $p)) { return @() }
    return @(Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch '^\.'
    } | ForEach-Object { $_.Name })
}

function Get-RBFiles {
    param([string]$Name)
    $p = Join-Path $Root $Name
    if (-not (Test-Path -LiteralPath $p)) { return @() }
    if ((Get-Item -LiteralPath $p).PSIsContainer) {
        return @(Get-ChildItem -LiteralPath $p -File -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -notmatch '^\.'
        } | ForEach-Object { $_.Name })
    }
    return @((Get-Item -LiteralPath $p).Name)
}
