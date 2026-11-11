# generateDatabase.ps1 — section database : commandes, driver, variables d'env, infra par moteur
# Section variable : n'apparaît que si database/ existe à la racine.

. (Join-Path $PSScriptRoot 'utils.ps1')
. (Join-Path $PSScriptRoot 'i18n.ps1')

function Generate-RBDatabaseSection {
    param($Inv, [string]$Lang)

    if ($Inv.Domains -notcontains 'database') { return '' }

    $h = Get-RBI18n 'sections.database' $Lang
    if ($h -eq 'sections.database') { $h = 'Database' }
    $md = "## $h`n`n"

    # Commandes db.*
    $dbFiles = Get-RBFiles 'database'
    $cmdRows = @()
    foreach ($f in $dbFiles) {
        if ($f -like '*.ps1' -or $f -like '*.ts') {
            $cmdRows += "| ``database/$f`` | |"
        }
    }
    if ($cmdRows.Count -gt 0) {
        $md += "| Command | Description |`n|---------|-------------|`n" + ($cmdRows -join "`n") + "`n`n"
    }

    # Driver ORM
    $orms = @('drizzle.ts', 'prisma.ts', 'typeorm.ts', 'sequelize.ts', 'knex.ts')
    $foundOrm = @()
    foreach ($o in $orms) {
        if ($dbFiles -contains $o) { $foundOrm += $o }
    }
    if ($foundOrm.Count -gt 0) {
        $md += "**ORM :** " + ($foundOrm | ForEach-Object { "```$_```" }) -join ', ' + "`n`n"
    }

    # Variables d'env
    $envFiles = @('.env', '.env.example', '.env.local', 'database/.env')
    $envPath = $null
    foreach ($ef in $envFiles) {
        if (Test-RBItem $ef) { $envPath = (Join-Path $Root $ef); break }
    }
    if ($envPath) {
        $raw = Read-RBFile $envPath
        $vars = @()
        foreach ($line in ($raw -split "`n")) {
            $t = $line.Trim()
            if ($t -match '^([A-Z0-9_]+)=') { $vars += $Matches[1] }
        }
        if ($vars.Count -gt 0) {
            $md += "**Environment variables :** " + ($vars | ForEach-Object { "```$_```" }) -join ', ' + "`n`n"
        }
    }

    # Infra par moteur
    $infraChildren = Get-RBChildNames 'database/infra'
    if ($infraChildren.Count -gt 0) {
        $md += "**Infrastructure :**" + "`n"
        $md += ($infraChildren | ForEach-Object {
            $p = Join-Path $Root (Join-Path 'database/infra' $_)
            if (Test-Path -LiteralPath $p -PathType Container) { "- ```$_/```" } else { "- ```$_```" }
        }) -join "`n"
        $md += "`n`n"
    }

    # Arborescence database/
    $tree = Get-RBTree -Dir (Join-Path $Root 'database') -MaxDepth 2
    if ($tree) {
        $md += "```" + "`n" + $tree + "```" + "`n`n"
    }

    return $md
}
