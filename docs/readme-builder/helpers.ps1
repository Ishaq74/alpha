# helpers.ps1 — slugs GitHub, liens de langue

function Get-RBSlug {
    param([string]$Str)
    $s = $Str.Trim().ToLowerInvariant()
    $s = [regex]::Replace($s, '[!"#$%&''()*+,./:;<>=?@\[\]^_`{|}~]', '')
    $s = [regex]::Replace($s, '\s+', '-')
    $s = [regex]::Replace($s, '-+', '-')
    return $s.Trim('-')
}

function Get-RBLangLinks {
    param([string]$CurrentLang)
    $langs = @('en', 'fr')
    $links = foreach ($lang in $langs) {
        $suffix = if ($lang -eq 'en') { '' } else { ".${lang}" }
        $label = if ($lang -eq $CurrentLang) { "**$($lang.ToUpper())**" } else { $lang.ToUpper() }
        "[$label](./README${suffix}.md)"
    }
    return ($links -join ' | ')
}
