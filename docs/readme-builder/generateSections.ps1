# generateSections.ps1 — structure immuable + sections variables par présence
# Immuable : titre, description (réservée vide), TOC, arborescence, commandes, licence
# Variable : tout ce que le scan détecte

. (Join-Path $PSScriptRoot 'utils.ps1')
. (Join-Path $PSScriptRoot 'i18n.ps1')
. (Join-Path $PSScriptRoot 'generateInventory.ps1')

function Generate-RBTitle {
    param($Inv, [string]$Lang)
    $name = 'Project'
    if ($Inv.TopLevel -contains 'package.json') {
        $raw = Read-RBFile (Join-Path $Root 'package.json')
        try { $n = ($raw | ConvertFrom-Json).name; if ($n) { $name = $n } } catch { }
    }
    return "# $name`n"
}

function Generate-RBDescription {
    param($Inv, [string]$Lang)
    $h = Get-RBI18n 'sections.description' $Lang
    return "## $h`n`n_Description to be written by the project owner._`n`n"
}

function Generate-RBTocSection {
    param([string]$Body, [string]$Lang)
    $toc = Get-RBToc $Body
    if (-not $toc) { return '' }
    $h = Get-RBI18n 'sections.toc' $Lang
    return "## $h`n`n$toc`n`n"
}

function Generate-RBTreeSection {
    param($Inv, [string]$Lang)
    $tree = Get-RBTree -Dir $Root -MaxDepth 2
    if (-not $tree) { return '' }
    $h = Get-RBI18n 'sections.structure' $Lang
    return "## $h`n`n````n$tree````n`n"
}

function Generate-RBCommandsSection {
    param($Inv, [string]$Lang)
    $rows = @()
    if ($Inv.TopLevel -contains 'package.json') {
        $raw = Read-RBFile (Join-Path $Root 'package.json')
        try {
            $pkg = $raw | ConvertFrom-Json
            $pkg.scripts.PSObject.Properties | ForEach-Object {
                $rows += "| ``$($_.Name)`` | ``$($_.Value)`` |"
            }
        } catch { }
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
    $files = Get-RBFiles $Domain
    $children = Get-RBChildNames $Domain
    if ($files.Count -eq 0 -and $children.Count -eq 0) { return '' }

    $h = Get-RBI18n "sections.$Domain" $Lang
    if ($h -eq "sections.$Domain") {
        $h = $Domain.ToUpperInvariant()[0] + $Domain.ToLowerInvariant().TrimStart($Domain.ToUpperInvariant()[0])
    }
    $md = "## $h`n`n"
    if ($children.Count -gt 0) {
        $md += ($children | ForEach-Object {
            if (Test-Path -LiteralPath (Join-Path $Root (Join-Path $Domain $_)) -PathType Container) { "- ``$_/``" } else { "- ``$_``" }
        }) -join "`n"
        $md += "`n`n"
    }
    return $md
}

function Generate-RBAllSections {
    param($Inv, [string]$Lang)

    $body = ''
    $body += Generate-RBTitle -Inv $inv -Lang $Lang
    $body += Generate-RBDescription -Inv $inv -Lang $Lang

    foreach ($d in $Inv.Domains) {
        $body += Generate-RBDomainSection -Inv $inv -Domain $d -Lang $Lang
    }

    $body += Generate-RBTreeSection -Inv $inv -Lang $Lang
    $body += Generate-RBCommandsSection -Inv $inv -Lang $Lang
    $body += Generate-RBLicenseSection -Inv $inv -Lang $Lang

    $toc = Generate-RBTocSection -Body $body -Lang $Lang
    $descEnd = $body.IndexOf('_Description to be written by the project owner._')
    if ($descEnd -ge 0) {
        $insertAt = $body.IndexOf("`n`n", $descEnd) + 2
        $body = $body.Insert($insertAt, $toc)
    } else {
        $body = $toc + $body
    }

    return $body
}
