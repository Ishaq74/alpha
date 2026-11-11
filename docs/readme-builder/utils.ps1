# utils.ps1 — socle du readme-builder
# Chemins, lecture de fichiers, listage d'arborescence, scripts package.json

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root       = Split-Path -Parent (Split-Path -Parent $ScriptRoot)

$Paths = @{
    Root       = $Root
    Src        = Join-Path $Root 'src'
    Components = Join-Path $Root 'src/components'
    Core       = Join-Path $Root 'src/core'
    Modules    = Join-Path $Root 'src/modules'
    Styles     = Join-Path $Root 'src/styles'
    Assets     = Join-Path $Root 'src/assets'
    Database   = Join-Path $Root 'src/database'
    Schemas    = Join-Path $Root 'src/database/schemas'
    Lib        = Join-Path $Root 'src/lib'
    Actions    = Join-Path $Root 'src/actions'
    Media      = Join-Path $Root 'src/media'
    Smpt       = Join-Path $Root 'src/smtp'
    I18nDir    = Join-Path $Root 'src/i18n'
    Pages      = Join-Path $Root 'src/pages'
    Layouts    = Join-Path $Root 'src/layouts'
    Tests      = Join-Path $Root 'tests'
    Github     = Join-Path $Root '.github'
    Logs       = Join-Path $Root 'logs'
    Public     = Join-Path $Root 'public'
    PackageJson = Join-Path $Root 'package.json'
    EnvExample  = Join-Path $Root '.env.example'
    Tsconfig   = Join-Path $Root 'tsconfig.json'
    Create     = Join-Path $Root 'create'
    LibPs      = Join-Path $Root 'lib'
    Ai         = Join-Path $Root 'ai'
    Docs       = Join-Path $Root 'docs'
    DatabaseRoot = Join-Path $Root 'database'
    SmptRoot   = Join-Path $Root 'smtp'
}

function Read-RBFile {
    param([string]$FilePath)
    if (Test-Path -LiteralPath $FilePath) {
        return Get-Content -LiteralPath $FilePath -Raw -ErrorAction SilentlyContinue
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
    $result = ''
    Get-ChildItem -LiteralPath $Dir -Force | Where-Object {
        $_.Name -notmatch '^\.' -and $_.Name -ne 'node_modules' -and $_.Name -ne 'dist'
    } | ForEach-Object {
        $indent = '  ' * $Depth
        if ($_.PSIsContainer) {
            $result += "$indent$($_.Name)/`n"
            $result += Get-RBTree -Dir $_.FullName -Depth ($Depth + 1) -MaxDepth $MaxDepth
        } else {
            $result += "$indent$($_.Name)`n"
        }
    }
    return $result
}

function Get-RBFiles {
    param([string]$Dir)
    if (-not (Test-Path -LiteralPath $Dir)) { return @() }
    return (Get-ChildItem -LiteralPath $Dir -File -Force | Where-Object {
        $_.Name -notmatch '^\.'
    }).Name
}

function Get-RBScriptsByPrefix {
    param([string[]] $Prefixes)
    $content = Read-RBFile $Paths.PackageJson
    if (-not $content) { return '' }
    try {
        $pkg = $content | ConvertFrom-Json
    } catch {
        return ''
    }
    $scripts = @($pkg.scripts.PSObject.Properties)
    $filtered = $scripts | Where-Object {
        $name = $_.Name
        $Prefixes | Where-Object { $name -eq $_ -or $name.StartsWith("$_:") -or $name.StartsWith("$_-") }
    }
    if ($filtered.Count -eq 0) { return '' }
    $rows = ($filtered | ForEach-Object { "| ``$($_.Name)`` |" }) -join "`n"
    return "| Command |`n|---------|`n$($rows -join "`n")"
}

function Find-RBTestsByPattern {
    param([string[]] $Patterns)
    $results = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $Paths.Tests)) { return $results }
    $queue = [System.Collections.Generic.Queue[string]]::new()
    $queue.Enqueue($Paths.Tests)
    while ($queue.Count -gt 0) {
        $dir = $queue.Dequeue()
        Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -notmatch '^\.' -and $_.Name -ne 'node_modules'
        } | ForEach-Object {
            if ($_.PSIsContainer) {
                $queue.Enqueue($_.FullName)
            } else {
                if ($_.Name -match '\.(test|spec)\.(ts|js)$') {
                    $rel = $_.FullName.Replace($Paths.Root + [IO.Path]::DirectorySeparatorChar, '').Replace('\', '/')
                    foreach ($p in $Patterns) {
                        if ($_.Name.Contains($p)) {
                            [void]$results.Add($rel)
                            break
                        }
                    }
                }
            }
        }
    }
    return $results
}
