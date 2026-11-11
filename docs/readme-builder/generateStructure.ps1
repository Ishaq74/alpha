# generateStructure.ps1 — arborescence détaillée avec contrôle de profondeur
# Section variable : profondeur pilotée par paramètre, défaut 3.

. (Join-Path $PSScriptRoot 'utils.ps1')
. (Join-Path $PSScriptRoot 'i18n.ps1')

function Generate-RBStructureSection {
    param(
        $Inv,
        [string]$Lang,
        [int]$MaxDepth = 3
    )

    $tree = Get-RBTree -Dir $Root -MaxDepth $MaxDepth
    if (-not $tree) { return '' }

    $h = Get-RBI18n 'sections.structure' $Lang
    return "## $h`n`n```" + "`n" + $tree + "```" + "`n`n"
}
