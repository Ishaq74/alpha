# helpers.ps1 — slug GitHub, TOC immuable

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
