# generateInventory.ps1 — inventaire du projet par présence
# Aucun if par techno : on scanne, on construit le motif, on rapporte.

. (Join-Path $PSScriptRoot 'utils.ps1')

function Get-RBInventory {
    $inv = [ordered]@{
        HasPackageJson = Test-Path -LiteralPath $Paths.PackageJson
        HasEnvExample  = Test-Path -LiteralPath $Paths.EnvExample
        HasTsconfig    = Test-Path -LiteralPath $Paths.Tsconfig
        HasSrc         = Test-Path -LiteralPath $Paths.Src
        HasComponents  = Test-Path -LiteralPath $Paths.Components
        HasCore        = Test-Path -LiteralPath $Paths.Core
        HasModules     = Test-Path -LiteralPath $Paths.Modules
        HasStyles      = Test-Path -LiteralPath $Paths.Styles
        HasAssets      = Test-Path -LiteralPath $Paths.Assets
        HasDatabase    = Test-Path -LiteralPath $Paths.DatabaseRoot
        HasDbInfra     = Test-Path -LiteralPath (Join-Path $Paths.DatabaseRoot 'infra')
        HasDbCommands  = Test-Path -LiteralPath (Join-Path $Paths.DatabaseRoot 'commands')
        HasDrizzle     = Test-Path -LiteralPath (Join-Path $Paths.DatabaseRoot 'drizzle.ts')
        HasSmpt        = Test-Path -LiteralPath $Paths.SmptRoot
        HasSmptProviders = Test-Path -LiteralPath (Join-Path $Paths.SmptRoot 'providers')
        HasSmptTemplates = Test-Path -LiteralPath (Join-Path $Paths.SmptRoot 'templates')
        HasSmptSend    = Test-Path -LiteralPath (Join-Path $Paths.SmptRoot 'send.ts')
        HasCreate      = Test-Path -LiteralPath $Paths.Create
        HasLib         = Test-Path -LiteralPath $Paths.LibPs
        HasAi          = Test-Path -LiteralPath $Paths.Ai
        HasAiAgents    = Test-Path -LiteralPath (Join-Path $Paths.Ai 'agents')
        HasOpencode    = Test-Path -LiteralPath (Join-Path $Root '.opencode')
        HasDocs        = Test-Path -LiteralPath $Paths.Docs
        HasTests       = Test-Path -LiteralPath $Paths.Tests
        HasGithub      = Test-Path -LiteralPath $Paths.Github
        HasPublic      = Test-Path -LiteralPath $Paths.Public
        HasMedia       = Test-Path -LiteralPath $Paths.Media
        HasActions     = Test-Path -LiteralPath $Paths.Actions
        HasPages       = Test-Path -LiteralPath $Paths.Pages
        HasLayouts     = Test-Path -LiteralPath $Paths.Layouts
        HasI18nDir     = Test-Path -LiteralPath $Paths.I18nDir
        HasSchemas     = Test-Path -LiteralPath $Paths.Schemas
        HasLogs        = Test-Path -LiteralPath $Paths.Logs
    }

    # Détection runtime / gestionnaire de paquets par présence de binaires
    $inv.Runtime = @()
    foreach ($cmd in @('node', 'bun', 'deno', 'php', 'python', 'python3', 'ruby', 'go', 'rustc', 'java')) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) { $inv.Runtime += $cmd }
    }
    $inv.PackageManager = @()
    foreach ($cmd in @('pnpm', 'npm', 'yarn', 'bun', 'composer', 'pip', 'pip3', 'cargo', 'go')) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) { $inv.PackageManager += $cmd }
    }

    # Lecture package.json si présent
    $inv.PackageName = ''
    $inv.PackageScripts = @()
    if ($inv.HasPackageJson) {
        $raw = Read-RBFile $Paths.PackageJson
        try {
            $pkg = $raw | ConvertFrom-Json
            $inv.PackageName = $pkg.name
            $inv.PackageScripts = @($pkg.scripts.PSObject.Properties.Name)
        } catch { }
    }

    # Moteurs de base détectés par présence de dossiers infra
    $inv.DbEngines = @()
    $infraDir = Join-Path $Paths.DatabaseRoot 'infra'
    if (Test-Path -LiteralPath $infraDir) {
        Get-ChildItem -LiteralPath $infraDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $inv.DbEngines += $_.Name.ToLowerInvariant()
        }
    }

    # Providers SMTP détectés par présence
    $inv.SmptProviders = @()
    $provDir = Join-Path $Paths.SmptRoot 'providers'
    if (Test-Path -LiteralPath $provDir) {
        Get-ChildItem -LiteralPath $provDir -File -ErrorAction SilentlyContinue | ForEach-Object {
            $inv.SmptProviders += $_.BaseName.ToLowerInvariant()
        }
    }

    return $inv
}
