# ---------------------------------------------------------------------------
# lib/readme.ps1 - Socle du readme-builder (pur PowerShell, zéro dépendance)
# Fonctions réutilisables : scan, inventaire, sections, i18n, slug, TOC.
# La racine cible est stockée dans $script:RBRoot (définie par le point d'entrée).
# ---------------------------------------------------------------------------

$script:RBRoot = $null
$script:RBI18nLoaded = @{}
$script:RBI18nCache = @{}

function Set-RBRoot {
    param([string]$Path)
    if (-not $Path) { $Path = (Get-Location).Path }
    $script:RBRoot = (Resolve-Path -LiteralPath $Path).Path
}

function Get-RBRoot {
    if (-not $script:RBRoot) { Set-RBRoot }
    return $script:RBRoot
}

function Read-RBFile {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        return (Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue)
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
    $root = Get-RBRoot
    if (-not (Test-Path -LiteralPath $root)) { return @() }
    return @(Get-ChildItem -LiteralPath $root -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch '^\.'
    } | ForEach-Object { $_.Name })
}

function Test-RBItem {
    param([string]$Name)
    $root = Get-RBRoot
    return (Test-Path -LiteralPath (Join-Path $root $Name))
}

function Get-RBChildNames {
    param([string]$Name)
    $root = Get-RBRoot
    $p = Join-Path $root $Name
    if (-not (Test-Path -LiteralPath $p)) { return @() }
    return @(Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -notmatch '^\.'
    } | ForEach-Object { $_.Name })
}

function Get-RBFiles {
    param([string]$Name)
    $root = Get-RBRoot
    $p = Join-Path $root $Name
    if (-not (Test-Path -LiteralPath $p)) { return @() }
    if ((Get-Item -LiteralPath $p).PSIsContainer) {
        return @(Get-ChildItem -LiteralPath $p -File -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -notmatch '^\.'
        } | ForEach-Object { $_.Name })
    }
    return @((Get-Item -LiteralPath $p).Name)
}

function Get-RBSlug {
    param([string]$Str)
    $s = $Str.Trim().ToLowerInvariant()
    $s = [regex]::Replace($s, '[!"#$%&''()*+,./:;<>=?@\[\]^_`{|}~]', '')
    $s = [regex]::Replace($s, '\s+', '-')
    $s = [regex]::Replace($s, '-+', '-')
    return $s.Trim('-')
}

function Get-RBToc {
    param([string]$Body)
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($Body -split "`n")) {
        if ($line -match '^##\s+(.+)$') {
            $title = $Matches[1].Trim()
            $anchor = Get-RBSlug $title
            $lines.Add("- [$title](#$anchor)")
        }
    }
    if ($lines.Count -eq 0) { return '' }
    return ($lines -join "`n")
}

# i18n
$script:RBI18nDir = $null
function Set-RBI18nDir {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path)
    $script:RBI18nDir = $Path
}
function Get-RBI18nDir {
    if (-not $script:RBI18nDir) {
        $script:RBI18nDir = Join-Path $PSScriptRoot '..\docs\readme-builder\i18n'
    }
    return $script:RBI18nDir
}

function Get-RBI18n {
    param(
        [string]$Section,
        [string]$Lang = 'en'
    )
    $dir = Get-RBI18nDir
    if (-not $script:RBI18nLoaded.ContainsKey($Lang)) {
        $script:RBI18nLoaded[$Lang] = $false
        $script:RBI18nCache[$Lang] = @{}
        $f = Join-Path $dir "$Lang.json"
        if (Test-Path -LiteralPath $f) {
            try {
                $script:RBI18nCache[$Lang] = (Get-Content -LiteralPath $f -Raw | ConvertFrom-Json)
                $script:RBI18nLoaded[$Lang] = $true
            } catch {
                Write-Warning "Echec du chargement de $f : $_"
            }
        }
    }
    $obj = $script:RBI18nCache[$Lang]
    if ($null -eq $obj) { return $Section }
    $parts = $Section -split '\.'
    $cur = $obj
    foreach ($p in $parts) {
        if ($cur.PSObject.Properties.Name -contains $p) {
            $cur = $cur.$p
        } else {
            return $Section
        }
    }
    if ($cur -is [string]) { return $cur }
    return $Section
}

function Test-RBI18nLoaded {
    param([string]$Lang = 'en')
    $dir = Get-RBI18nDir
    return (Test-Path -LiteralPath (Join-Path $dir "$Lang.json"))
}

# Inventory
function Get-RBInventory {
    $root = Get-RBRoot
    $top = Get-RBTopLevel

    $inv = [ordered]@{
        TopLevel       = $top
        Runtime        = @()
        PackageManager = @()
        Languages      = @()
        Domains        = @()
    }

    foreach ($cmd in @('node','bun','deno','php','python','python3','ruby','go','rustc','java','powershell','pwsh')) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) { $inv.Runtime += $cmd }
    }

    foreach ($cmd in @('pnpm','npm','yarn','bun','composer','pip','pip3','cargo','go','gem')) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) { $inv.PackageManager += $cmd }
    }

    $exts = @{}
    $queue = [System.Collections.Generic.Queue[string]]::new()
    $queue.Enqueue($root)
    $seen = 0
    while ($queue.Count -gt 0 -and $seen -lt 500) {
        $dir = $queue.Dequeue()
        $seen++
        Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -notmatch '^\.' -and $_.Name -ne 'node_modules' -and $_.Name -ne 'dist' -and $_.Name -ne '.git'
        } | ForEach-Object {
            if ($_.PSIsContainer) {
                $queue.Enqueue($_.FullName)
            } else {
                $e = $_.Extension.ToLowerInvariant()
                if ($e) {
                    if (-not $exts.ContainsKey($e)) { $exts[$e] = 0 }
                    $exts[$e]++
                }
            }
        }
    }
    $map = @{
        '.ts'='TypeScript'; '.js'='JavaScript'; '.tsx'='TypeScript'; '.jsx'='JavaScript'
        '.py'='Python'; '.php'='PHP'; '.rb'='Ruby'; '.go'='Go'; '.rs'='Rust'
        '.java'='Java'; '.c'='C'; '.cpp'='C++'; '.cs'='C#'; '.swift'='Swift'
        '.kt'='Kotlin'; '.ps1'='PowerShell'; '.sh'='Shell'; '.sql'='SQL'
        '.html'='HTML'; '.css'='CSS'; '.json'='JSON'; '.yml'='YAML'; '.yaml'='YAML'
        '.md'='Markdown'; '.toml'='TOML'
    }
    foreach ($e in $exts.Keys) {
        if ($map.ContainsKey($e)) { $inv.Languages += $map[$e] }
    }
    $inv.Languages = @($inv.Languages | Select-Object -Unique | Sort-Object)

    $skip = @('.opencode','node_modules','dist','.git','docs')
    $inv.Domains = @($top | Where-Object { $skip -notcontains $_ -and (Test-Path -LiteralPath (Join-Path $root $_) -PathType Container) })

    return $inv
}

# Sections
function Generate-RBTitle {
    param($Inv, [string]$Lang)
    $null = $Lang
    $root = Get-RBRoot
    $name = 'Project'
    foreach ($rel in @('docs/who.md','who.md')) {
        if (Test-RBItem $rel) {
            $raw = (Read-RBFile (Join-Path $root $rel)).Trim()
            if ($raw) {
                $first = ($raw -split "`n")[0].Trim()
                if ($first) { $name = $first; break }
            }
        }
    }
    if ($name -eq 'Project' -and ($Inv.TopLevel -contains 'package.json')) {
        $raw = Read-RBFile (Join-Path $root 'package.json')
        try { $n = ($raw | ConvertFrom-Json).name; if ($n) { $name = $n } } catch { Write-Warning "Echec du parsing de package.json : $_" }
    }
    return "# $name`n"
}

function Generate-RBWhatSection {
    param($Inv, [string]$Lang)
    $null = $Inv
    $null = $Lang
    $root = Get-RBRoot
    $h = Get-RBI18n 'sections.what' $Lang
    $desc = '_Description to be written by the project owner._'
    foreach ($rel in @('docs/what.md','what.md')) {
        if (Test-RBItem $rel) {
            $raw = (Read-RBFile (Join-Path $root $rel)).Trim()
            if ($raw) { $desc = $raw; break }
        }
    }
    return "## $h`n`n$desc`n`n"
}

function Generate-RBTocSection {
    param([string]$Body, [string]$Lang)
    $toc = Get-RBToc $Body
    if (-not $toc) { return '' }
    $h = Get-RBI18n 'sections.toc' $Lang
    return "## $h`n`n$toc`n`n"
}


function Generate-RBCommandsSection {
    param($Inv, [string]$Lang)
    $root = Get-RBRoot
    $rows = @()
    if ($Inv.TopLevel -contains 'package.json') {
        $raw = Read-RBFile (Join-Path $root 'package.json')
        try {
            $pkg = $raw | ConvertFrom-Json
            $pkg.scripts.PSObject.Properties | ForEach-Object {
                $rows += "| ``$($_.Name)`` | ``$($_.Value)`` |"
            }
        } catch { Write-Warning "Echec du parsing de package.json : $_" }
    }
    if ($Inv.TopLevel -contains 'create') {
        Get-RBFiles 'create' | Where-Object { $_ -like '*.ps1' } | ForEach-Object {
            $rows += "| ``./create/$_`` | PowerShell script |"
        }
    }
    if ($rows.Count -eq 0) { return '' }
    $h = Get-RBI18n 'sections.commands' $Lang
    $table = "| Command | Description |`n|---------|-------------|`n" + ($rows -join "`n")
    return "## $h`n`n$($table -join "`n")`n`n"
}

function Generate-RBLicenseSection {
    param($Inv, [string]$Lang)
    $lic = $null
    foreach ($f in @('LICENSE','LICENSE.md','LICENCE','LICENCE.md')) {
        if ($Inv.TopLevel -contains $f) { $lic = $f; break }
    }
    if (-not $lic) { return '' }
    $h = Get-RBI18n 'sections.license' $Lang
    return "## $h`n`nSee [$lic](./$lic).`n`n"
}

function Generate-RBDomainSection {
    param($Inv, [string]$Domain, [string]$Lang)
    $null = $Inv
    $null = $Lang
    $root = Get-RBRoot
    $files = Get-RBFiles $Domain
    $children = Get-RBChildNames $Domain
    if ($files.Count -eq 0 -and $children.Count -eq 0) { return ' }

    $docDir = Join-Path $root $Domain
    $tempDir = $docDir
    $docDir = "$tempDir\docs"
    $whoPath = $docDir
    $whoPath = "$whoPath\who.md"
    if (Test-Path -LiteralPath $whoPath) {
        $sep = "\\"
        $who = (Read-RBFile $whoPath).Trim()
        $who = ''
    }
    $what = if (Test-Path -LiteralPath (Join-Path $docDir 'what.md')) { (Read-RBFile (Join-Path $docDir 'what.md')).Trim() } else { '' }
    $whatPath = Join-Path $docDir 'what.md'
    if (Test-Path -LiteralPath $whatPath) {
        $what = (Read-RBFile $whatPath).Trim()
    } else {
        $what = ''
    }
    $howPath = Join-Path $docDir 'how.md'
    if (Test-Path -LiteralPath $howPath) {
        $how = (Read-RBFile $howPath).Trim()
    } else {
        $how = ''
    }
        $what = (Read-RBFile (Join-Path $docDir 'what.md')).Trim()
    } else {
        $what = ''
    }
    if (Test-Path -LiteralPath (Join-Path $docDir 'how.md')) {
        $how = (Read-RBFile (Join-Path $docDir 'how.md')).Trim()
    } else {
        $how = ''
    }
    $domainReadme = Join-Path $root (Join-Path $Domain 'README.md')
    if (Test-Path -LiteralPath $domainReadme) {
        $content = (Read-RBFile $domainReadme).Trim()
        if ($content) { return "$content`n`n" }
    }

    $h = Get-RBI18n "sections.$Domain" $Lang
    if ($h -eq "sections.$Domain") {
        $h = $Domain.ToUpperInvariant()[0] + $Domain.ToLowerInvariant().TrimStart($Domain.ToUpperInvariant()[0])
    }
    $md = ''
    if ($who) { $md += "$who`n`n" }
    else { $md += "## $h`n`n" }
    if ($what) { $md += "$what`n`n" }
    if ($how) { $md += "### How`n`n$how`n`n" }
    if ($children.Count -gt 0) {
        $md += ($children | ForEach-Object {
            if (Test-Path -LiteralPath (Join-Path $root (Join-Path $Domain $_)) -PathType Container) { "- ``$_/``" } else { "- ``$_``" }
        }) -join "`n"
        $md += "`n`n"
    }
    return $md
}
function Generate-RBDatabaseSection {
    param($Inv, [string]$Lang)
    $root = Get-RBRoot
    if ($Inv.Domains -notcontains 'database') { return '' }

    $docDir = Join-Path $root 'database/docs'
    $who = if (Test-Path -LiteralPath (Join-Path $docDir 'who.md')) { (Read-RBFile (Join-Path $docDir 'who.md')).Trim() } else { '' }
    $what = if (Test-Path -LiteralPath (Join-Path $docDir 'what.md')) { (Read-RBFile (Join-Path $docDir 'what.md')).Trim() } else { '' }
    $how = if (Test-Path -LiteralPath (Join-Path $docDir 'how.md')) { (Read-RBFile (Join-Path $docDir 'how.md')).Trim() } else { '' }

    $domainReadme = Join-Path $root 'database/README.md'
    if (Test-Path -LiteralPath $domainReadme) {
        $content = (Read-RBFile $domainReadme).Trim()
        if ($content) { return "$content`n`n" }
    }

    if ($who -or $what -or $how) {
        $md = ''
        if ($who) { $md += "$who`n`n" }
        if ($what) { $md += "$what`n`n" }
        if ($how) { $md += "### How`n`n$how`n`n" }
        return $md
    }


    # Si database/ a son propre README.md, l'integrer
    $domainReadme = Join-Path $root 'database/README.md'
    if (Test-Path -LiteralPath $domainReadme) {
        $content = (Read-RBFile $domainReadme).Trim()
        if ($content) { return "$content`n`n" }
    }

    $h = Get-RBI18n 'sections.database' $Lang
    if ($h -eq 'sections.database') { $h = 'Database' }
    $md = "## $h`n`n"

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

    $orms = @('drizzle.ts', 'prisma.ts', 'typeorm.ts', 'sequelize.ts', 'knex.ts')
    $foundOrm = @()
    foreach ($o in $orms) {
        if ($dbFiles -contains $o) { $foundOrm += $o }
    }
    if ($foundOrm.Count -gt 0) {
        $md += "**ORM :** " + ($foundOrm | ForEach-Object { "``$_``" }) -join ', ' + "`n`n"
    }

    $envFiles = @('.env', '.env.example', '.env.local', 'database/.env')
    $envPath = $null
    foreach ($ef in $envFiles) {
        if (Test-RBItem $ef) { $envPath = (Join-Path $root $ef); break }
    }
    if ($envPath) {
        $raw = Read-RBFile $envPath
        $vars = @()
        foreach ($line in ($raw -split "`n")) {
            $t = $line.Trim()
            if ($t -match '^([A-Z0-9_]+)=') { $vars += $Matches[1] }
        }
        if ($vars.Count -gt 0) {
            $md += "**Environment variables :** " + ($vars | ForEach-Object { "``$_``" }) -join ', ' + "`n`n"
        }
    }

    $infraChildren = Get-RBChildNames 'database/infra'
    if ($infraChildren.Count -gt 0) {
        $md += "**Infrastructure :**" + "`n"
        $md += ($infraChildren | ForEach-Object {
            $p = Join-Path $root (Join-Path 'database/infra' $_)
            if (Test-Path -LiteralPath $p -PathType Container) { "- ``$_/``" } else { "- ``$_``" }
        }) -join "`n"
        $md += "`n`n"
    }

    $tree = Get-RBTree -Dir (Join-Path $root 'database') -MaxDepth 2
    if ($tree) {
        $md += "````n" + $tree + "````n`n"
    }

    return $md
}

function Generate-RBStructureSection {
    param(
        $Inv,
        [string]$Lang,
        [int]$MaxDepth = 3
    )
    $tree = Get-RBTree -Dir (Get-RBRoot) -MaxDepth $MaxDepth
    if (-not $tree) { return '' }
    $null = $Inv
    $null = $Lang
    $null = $MaxDepth
    $h = Get-RBI18n 'sections.structure' $Lang
    return "## $h`n`n````n$tree````n`n"
}

function Generate-RBAllSections {
    param($Inv, [string]$Lang, [int]$MaxDepth = 3)

    $body = ''
    $body += Generate-RBTitle -Inv $inv -Lang $Lang
    $body += Generate-RBWhatSection -Inv $inv -Lang $Lang

    foreach ($d in $Inv.Domains) {
        if ($d -eq 'database') {
            $body += Generate-RBDatabaseSection -Inv $inv -Lang $Lang
        } else {
            $body += Generate-RBDomainSection -Inv $inv -Domain $d -Lang $Lang
        }
    }

    $body += Generate-RBStructureSection -Inv $inv -Lang $Lang -MaxDepth $MaxDepth
    $body += Generate-RBCommandsSection -Inv $inv -Lang $Lang
    $body += Generate-RBLicenseSection -Inv $inv -Lang $Lang

    $toc = Generate-RBTocSection -Body $body -Lang $Lang
    $titleEnd = $body.IndexOf("`n")
    $start = if ($titleEnd -ge 0) { $titleEnd } else { 0 }
    $whatPos = $body.IndexOf("`n## ", $start)
    if ($whatPos -ge 0) {
        $nextHeading = $body.IndexOf("`n#", $whatPos + 4)
        if ($nextHeading -ge 0) {
            $body = $body.Insert($nextHeading + 1, $toc)
        } else {
            $body = $body + "`n" + $toc
        }
    } else {
        $body = $body + "`n" + $toc
    }

    # Normalisation markdown
    # MD022 : headings entoures de lignes vides
    $body = [regex]::Replace($body, '(?<!\n)\n(#{1,6}\s)', "`n`n`$1")
    $body = [regex]::Replace($body, '(#{1,6}\s[^\n]+)\n(?!\n)', "`$1`n`n")
    # MD032 : listes entourees de lignes vides
    $body = [regex]::Replace($body, '(?<!\n)\n(- |\* |\d+\. )', "`n`n`$1")
    $body = [regex]::Replace($body, '(- |\* |\d+\. [^\n]+)\n(?!\n|- |\* |\d+\. )', "`$1`n`n")
    # MD060 : tableaux avec espaces autour des pipes (normalisation par ligne)
    $body = [regex]::Replace($body, '(?m)^\|[-\s|]+\|$', { param($m)
        $cols = $m.Value -split '\|'
        $out = ''
        for ($i = 1; $i -lt $cols.Count - 1; $i++) {
            $out += '| --- '
        }
        $out += '|'
        return $out
    })
    return $body
}
