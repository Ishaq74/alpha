# readme-generate.ps1 — point d'entrée du readme-builder
# PowerShell pur, zéro dépendance, détection par présence.
# Usage : .\readme-generate.ps1 [-Lang en|fr]

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param(
    [ValidateSet('en', 'fr')]
    [string]$Lang = 'en'
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'utils.ps1')
. (Join-Path $PSScriptRoot 'helpers.ps1')
. (Join-Path $PSScriptRoot 'i18n.ps1')
. (Join-Path $PSScriptRoot 'generateInventory.ps1')
. (Join-Path $PSScriptRoot 'generateSections.ps1')

function Invoke-RBGenerate {
    param([string]$Lang)

    $inv = Get-RBInventory

    $md = "# $(Get-RBI18n 'projectName' $Lang)`n`n"
    $md += "$(Get-RBLangLinks $Lang)`n`n"
    $md += "$(Get-RBI18n 'description' $Lang)`n`n"
    $body = ''
    $body += Generate-RBOverview -Inv $inv -Lang $Lang
    $body += Generate-RBGettingStarted -Inv $inv -Lang $Lang
    $body += Generate-RBStructure -Inv $inv -Lang $Lang
    $body += Generate-RBDatabase -Inv $inv -Lang $Lang
    $body += Generate-RBSmpt -Inv $inv -Lang $Lang
    $body += Generate-RBCreate -Inv $inv -Lang $Lang
    $body += Generate-RBLib -Inv $inv -Lang $Lang
    $body += Generate-RBAi -Inv $inv -Lang $Lang
    $body += Generate-RBTests -Inv $inv -Lang $Lang
    $body += Generate-RBCicd -Inv $inv -Lang $Lang

    # TOC auto
    $tocLines = [System.Collections.Generic.List[string]]::new()
    $headingRegex = [regex]'^##\s+(.+)$'
    foreach ($line in ($body -split "`n")) {
        $m = $headingRegex.Match($line)
        if ($m.Success) {
            $title = $m.Groups[1].Value.Trim()
            $anchor = Get-RBSlug $title
            $tocLines.Add("- [$title](#$anchor)")
        }
    }
    if ($tocLines.Count -gt 0) {
        $md += "## $(Get-RBI18n 'toc' $Lang)`n`n" + ($tocLines -join "`n") + "`n`n"
    }

    $md += $body
    $md = [regex]::Replace($md, '\n{3,}', "`n`n")
    if (-not $md.EndsWith("`n")) { $md += "`n" }

    $suffix = if ($Lang -eq 'en') { '' } else { ".${Lang}" }
    $outDir = Join-Path $Root 'docs'
    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir | Out-Null
    }
    $outPath = Join-Path $outDir "README${suffix}.md"
    Set-Content -LiteralPath $outPath -Value $md -Encoding utf8
    Write-Host "README${suffix}.md generated -> $outPath"
}

foreach ($l in $Langs) {
    Invoke-RBGenerate -Lang $l
}
