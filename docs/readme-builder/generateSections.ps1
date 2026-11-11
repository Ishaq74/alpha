# generateSections.ps1 — une fonction par section du README
# Chaque section lit l'inventaire et écrit ou se tait. Pas de if par techno.

. (Join-Path $PSScriptRoot 'utils.ps1')
. (Join-Path $PSScriptRoot 'i18n.ps1')
. (Join-Path $PSScriptRoot 'generateInventory.ps1')

function Generate-RBOverview {
    param($Inv, [string]$Lang)
    $s = Get-RBI18n 'sections.overview' $Lang
    $md = "## $s`n`n"
    $md += (Get-RBI18n 'description' $Lang) + "`n`n"
    $md += (Get-RBI18n 'subtitle' $Lang) + "`n`n"
    if ($Inv.Runtime.Count -gt 0 -or $Inv.PackageManager.Count -gt 0) {
        $md += "### $(Get-RBI18n 'sections.techStack' $Lang)`n`n"
        if ($Inv.Runtime.Count -gt 0) {
            $md += "- **Runtime:** $($Inv.Runtime -join ', ')`n"
        }
        if ($Inv.PackageManager.Count -gt 0) {
            $md += "- **Package manager:** $($Inv.PackageManager -join ', ')`n"
        }
        if ($Inv.DbEngines.Count -gt 0) {
            $md += "- **Database engines:** $($Inv.DbEngines -join ', ')`n"
        }
        if ($Inv.SmptProviders.Count -gt 0) {
            $md += "- **SMTP providers:** $($Inv.SmptProviders -join ', ')`n"
        }
        $md += "`n"
    }
    return $md
}

function Generate-RBGettingStarted {
    param($Inv, [string]$Lang)
    $s = Get-RBI18n 'sections.gettingStarted' $Lang
    $md = "## $s`n`n"
    $md += "### $(Get-RBI18n 'subsections.prerequisites' $Lang)`n`n"
    if ($Inv.Runtime.Count -gt 0) {
        $md += ($Inv.Runtime | ForEach-Object { "- **$_**" }) -join "`n"
        $md += "`n`n"
    } else {
        $md += "- No runtime detected on this machine. The project itself declares none hard-coded.`n`n"
    }
    if ($Inv.HasPackageJson -and $Inv.PackageScripts.Count -gt 0) {
        $md += "### $(Get-RBI18n 'subsections.installation' $Lang)`n`n"
        $md += '```bash' + "`n"
        $first = $Inv.PackageScripts | Where-Object { $_ -match '^(install|dev|start|build)$' } | Select-Object -First 4
        foreach ($sc in $first) { $md += "pnpm $sc`n" }
        $md += '```' + "`n`n"
    }
    if ($Inv.HasEnvExample) {
        $md += "### $(Get-RBI18n 'subsections.envVars' $Lang)`n`n"
        $envContent = Read-RBFile $Paths.EnvExample
        if ($envContent) {
            $md += '```' + "`n" + $envContent.Trim() + "`n" + '```' + "`n`n"
        }
    }
    return $md
}

function Generate-RBStructure {
    param($Inv, [string]$Lang)
    if (-not $Inv.HasSrc -and -not $Inv.HasCreate -and -not $Inv.HasDatabase -and -not $Inv.HasSmpt -and -not $Inv.HasAi) {
        return ''
    }
    $title = if ($Lang -eq 'fr') { 'Structure' } else { 'Structure' }
    $md = "## $title`n`n"
    $md += '```' + "`n"
    $md += Get-RBTree -Dir $Root -MaxDepth 2
    $md += '```' + "`n`n"
    return $md
}

function Generate-RBDatabase {
    param($Inv, [string]$Lang)
    if (-not $Inv.HasDatabase) { return '' }
    $title = Get-RBI18n 'sections.database' $Lang
    $md = "## $title`n`n"
    if ($Inv.DbEngines.Count -gt 0) {
        $md += "Engines: $($Inv.DbEngines -join ', ')`n`n"
    }
    $scripts = Get-RBScriptsByPrefix -Prefixes @('db')
    if ($scripts) { $md += $scripts + "`n`n" }
    $files = Get-RBFiles $Paths.DatabaseRoot
    if ($files.Count -gt 0) {
        $md += ($files | ForEach-Object { "- ``$_``" }) -join "`n"
        $md += "`n`n"
    }
    return $md
}

function Generate-RBSmpt {
    param($Inv, [string]$Lang)
    if (-not $Inv.HasSmpt) { return '' }
    $title = Get-RBI18n 'sections.email' $Lang
    $md = "## $title`n`n"
    if ($Inv.SmptProviders.Count -gt 0) {
        $md += "Providers: $($Inv.SmptProviders -join ', ')`n`n"
    }
    $files = Get-RBFiles $Paths.SmptRoot
    if ($files.Count -gt 0) {
        $md += ($files | ForEach-Object { "- ``$_``" }) -join "`n"
        $md += "`n`n"
    }
    return $md
}

function Generate-RBCreate {
    param($Inv, [string]$Lang)
    if (-not $Inv.HasCreate) { return '' }
    $title = if ($Lang -eq 'fr') { 'Création de projet' } else { 'Project Creation' }
    $md = "## $title`n`n"
    $files = Get-RBFiles $Paths.Create
    if ($files.Count -gt 0) {
        $md += ($files | ForEach-Object { "- ``$_``" }) -join "`n"
        $md += "`n`n"
    }
    return $md
}

function Generate-RBLib {
    param($Inv, [string]$Lang)
    if (-not $Inv.HasLib) { return '' }
    $title = if ($Lang -eq 'fr') { 'Socle partagé' } else { 'Shared Core' }
    $md = "## $title`n`n"
    $files = Get-RBFiles $Paths.LibPs
    if ($files.Count -gt 0) {
        $md += ($files | ForEach-Object { "- ``$_``" }) -join "`n"
        $md += "`n`n"
    }
    return $md
}

function Generate-RBAi {
    param($Inv, [string]$Lang)
    if (-not $Inv.HasAi) { return '' }
    $title = if ($Lang -eq 'fr') { 'Agents IA' } else { 'AI Agents' }
    $md = "## $title`n`n"
    if ($Inv.HasAiAgents) {
        $agents = Get-RBFiles (Join-Path $Paths.Ai 'agents')
        if ($agents.Count -gt 0) {
            $md += ($agents | ForEach-Object { "- ``$_``" }) -join "`n"
            $md += "`n`n"
        }
    }
    return $md
}

function Generate-RBTests {
    param($Inv, [string]$Lang)
    if (-not $Inv.HasTests) { return '' }
    $title = if ($Lang -eq 'fr') { 'Tests' } else { 'Tests' }
    $md = "## $title`n`n"
    $tests = Find-RBTestsByPattern -Patterns @('test', 'spec', 'ps1')
    if ($tests.Count -gt 0) {
        $md += ($tests | ForEach-Object { "- ``$_``" }) -join "`n"
        $md += "`n`n"
    }
    return $md
}

function Generate-RBCicd {
    param($Inv, [string]$Lang)
    if (-not $Inv.HasGithub) { return '' }
    $title = Get-RBI18n 'sections.cicd' $Lang
    $md = "## $title`n`n"
    $ghFiles = Get-RBTree -Dir $Paths.Github -MaxDepth 3
    if ($ghFiles) {
        $md += '```' + "`n" + $ghFiles + '```' + "`n`n"
    }
    return $md
}
