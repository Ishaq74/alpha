# Extension readme - genere le README.md a la creation du projet
# Hook : after_directory

. (Join-Path $PSScriptRoot '..\..\lib\readme.ps1')

Register-Hook 'after_directory' {
    if (-not $State.Dir -or -not (Test-Path -LiteralPath $State.Dir -PathType Container)) {
        Write-Warn "Répertoire cible invalide, génération du README ignorée."
        return
    }
    Set-RBRoot -Path $State.Dir
    Set-RBI18nDir -Path (Join-Path $PSScriptRoot '..\..\docs\readme-builder\i18n')
    $md = Generate-RBAllSections -Inv (Get-RBInventory) -Lang 'en' -MaxDepth 3
    $md = [regex]::Replace($md, '\n{3,}', "`n`n")
    if (-not $md.EndsWith("`n")) { $md += "`n" }
    $outPath = Join-Path $State.Dir 'README.md'
    if (-not $State.DryRun) {
        Set-Content -LiteralPath $outPath -Value $md -Encoding utf8
        Write-Ok "README.md genere : $outPath"
    } else {
        Write-Info "DRY-RUN: README.md -> $outPath"
    }
}
