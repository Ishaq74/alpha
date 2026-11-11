# generateInventory.ps1 — inventaire par présence, zéro hypothèse de framework

. (Join-Path $PSScriptRoot 'utils.ps1')

function Get-RBInventory {
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
    $queue.Enqueue($Root)
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
    $inv.Domains = @($top | Where-Object { $skip -notcontains $_ -and (Test-Path -LiteralPath (Join-Path $Root $_) -PathType Container) })

    return $inv
}
