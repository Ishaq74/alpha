# i18n.ps1 — traductions externes optionnelles
# Le builder ne contient AUCUN dictionnaire embarqué.
# Si docs/readme-builder/i18n/<lang>.json existe, il est chargé.
# Sinon, les en-têtes restent dans la langue par défaut (en).
# La description n'est JAMAIS remplie par le builder.

$I18nDir = Join-Path $PSScriptRoot 'i18n'
$Loaded = @{}

function Get-RBI18n {
    param(
        [string]$Section,
        [string]$Lang = 'en'
    )
    if (-not $Loaded.ContainsKey($Lang)) {
        $Loaded[$Lang] = @{}
        $f = Join-Path $I18nDir "$Lang.json"
        if (Test-Path -LiteralPath $f) {
            try {
                $Loaded[$Lang] = (Get-Content -LiteralPath $f -Raw | ConvertFrom-Json)
            } catch { }
        }
    }
    $obj = $Loaded[$Lang]
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
    return (Test-Path -LiteralPath (Join-Path $I18nDir "$Lang.json"))
}
