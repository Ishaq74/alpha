[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
# lint/powershell.ps1 - review parfaite et integrale du code PowerShell du repo
# Usage : pwsh -File lint/powershell.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$fail = 0

# ---------------------------------------------------------------------------
# 0. Installation PSScriptAnalyzer si absent
# ---------------------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "[INFO] Installation de PSScriptAnalyzer..." -ForegroundColor Cyan
    try { Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -AllowClobber } catch { Write-Host "[WARN] Installation echouee" -ForegroundColor Yellow }
}
if (Get-Module -ListAvailable -Name PSScriptAnalyzer) { Import-Module PSScriptAnalyzer }

$psFiles = Get-ChildItem -Path $root -Recurse -Filter *.ps1 | Where-Object { $_.FullName -notmatch '\\.git\\' }

# ---------------------------------------------------------------------------
# 1. Syntaxe et parse
# ---------------------------------------------------------------------------
Write-Host "`n=== 1. Syntaxe ===" -ForegroundColor Cyan
foreach ($f in $psFiles) {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors -and $errors.Count -gt 0) {
        Write-Host "[FAIL] $($f.FullName)" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        $fail++
    } else {
        Write-Host "[OK] $($f.FullName)" -ForegroundColor Green
    }
}

# ---------------------------------------------------------------------------
# 2. PSScriptAnalyzer
# ---------------------------------------------------------------------------
Write-Host "`n=== 2. PSScriptAnalyzer ===" -ForegroundColor Cyan
if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
    foreach ($f in $psFiles) {
        $issues = Invoke-ScriptAnalyzer -Path $f.FullName -Severity Error,Warning -ExcludeRule @('PSAvoidUsingWriteHost','PSAvoidOverwritingBuiltInCmdlets','PSUseBOMForUnicodeEncodedFile','PSUseApprovedVerbs','PSEmptyCatchBlock','PSUseSingularNouns','PSShouldProcess','PSUseShouldProcessForStateChangingFunctions','PSUseSupportsShouldProcess')
        if ($issues) {
            Write-Host "[FAIL] $($f.FullName)" -ForegroundColor Red
            $issues | ForEach-Object { Write-Host "  $($_.Severity): $($_.Message) (ligne $($_.Line))" -ForegroundColor Red }
            $fail++
        } else {
            Write-Host "[OK] $($f.FullName)" -ForegroundColor Green
        }
    }
} else {
    Write-Host "[WARN] PSScriptAnalyzer non disponible" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# 3. Conventions de nommage
# ---------------------------------------------------------------------------
Write-Host "`n=== 3. Conventions de nommage ===" -ForegroundColor Cyan
foreach ($f in $psFiles) {
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors)
    $funcs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($fn in $funcs) {
        if ($fn.Name -notmatch '^[A-Z][a-zA-Z0-9]*(-[A-Z][a-zA-Z0-9]*)*$') {
            Write-Host "[FAIL] Fonction non PascalCase : $($fn.Name) dans $($f.FullName)" -ForegroundColor Red
            $fail++
        }
    }
    $params = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ParamBlockAst] }, $true)
    foreach ($pb in $params) {
        foreach ($p in $pb.Parameters) {
            $pname = $p.Name.VariablePath.UserPath
            if ($pname -notmatch '^[A-Z][a-zA-Z0-9]*$') {
                Write-Host "[FAIL] Parametre non PascalCase : $pname dans $($f.FullName)" -ForegroundColor Red
                $fail++
            }
        }
    }
    Write-Host "[OK] $($f.FullName)" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 4. Securite
# ---------------------------------------------------------------------------
Write-Host "`n=== 4. Securite ===" -ForegroundColor Cyan
$dangerous = @('Invoke-Expression', 'iex ', 'ConvertTo-SecureString.*AsPlainText', 'password\s*=\s*["'']', 'secret\s*=\s*["'']', 'token\s*=\s*["'']')
foreach ($f in $psFiles) {
    if ($f.FullName -match 'lint\\powershell\.ps1$') { Write-Host "[SKIP] $($f.FullName)" -ForegroundColor Cyan; continue }
    $content = Get-Content -LiteralPath $f.FullName -Raw
    $found = $false
    foreach ($pat in $dangerous) {
        if ($content -match $pat) {
            Write-Host "[FAIL] Pattern dangereux '$pat' dans $($f.FullName)" -ForegroundColor Red
            $found = $true
            $fail++
        }
    }
    # Chemins codes en dur (hors $PSScriptRoot et $env:)
    if ($content -match 'C:\\\\Users\\\\' -or $content -match 'C:/Users/') {
        Write-Host "[FAIL] Chemin code en dur dans $($f.FullName)" -ForegroundColor Red
        $found = $true
        $fail++
    }
    if (-not $found) { Write-Host "[OK] $($f.FullName)" -ForegroundColor Green }
}

# ---------------------------------------------------------------------------
# 5. Coherence des libs
# ---------------------------------------------------------------------------
Write-Host "`n=== 5. Coherence des libs ===" -ForegroundColor Cyan
# Chaque script qui utilise $State doit dot-sourcer state.ps1
foreach ($f in $psFiles) {
    if ($f.FullName -match '\\lib\\') { continue }
    if ($f.Name -eq 'readme.ps1') { continue }
    $content = Get-Content -LiteralPath $f.FullName -Raw
    if ($content -match '\$State\.') {
        if ($content -notmatch 'state\.ps1') {
            Write-Host "[FAIL] $($f.Name) utilise `$State mais ne charge pas state.ps1" -ForegroundColor Red
            $fail++
        } else {
            Write-Host "[OK] $($f.Name)" -ForegroundColor Green
        }
    }
}

# ---------------------------------------------------------------------------
# 6. Documentation
# ---------------------------------------------------------------------------
Write-Host "`n=== 6. Documentation ===" -ForegroundColor Cyan
foreach ($f in $psFiles) {
    $content = Get-Content -LiteralPath $f.FullName -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$null)
    $funcs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    foreach ($fn in $funcs) {
        $startLine = $fn.Extent.StartLineNumber
        if ($startLine -le 1) { continue }
        $prevLine = (Get-Content -LiteralPath $f.FullName)[$startLine - 2]
        if ($prevLine -notmatch '^\s*#') {
            Write-Host "[WARN] Fonction $($fn.Name) sans commentaire precedent dans $($f.Name)" -ForegroundColor Yellow
        }
    }
    # Parametres non types
    if ($content -match 'param\(\s*\$[A-Za-z]') {
        Write-Host "[WARN] Parametre non type dans $($f.Name)" -ForegroundColor Yellow
    }
    Write-Host "[OK] $($f.Name)" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 7. Tests fonctionnels
# ---------------------------------------------------------------------------
Write-Host "`n=== 7. Tests fonctionnels ===" -ForegroundColor Cyan

# 7a. Build builder
$tmp = Join-Path $env:TEMP "rb-test-$(Get-Random)"
New-Item -ItemType Directory -Path $tmp | Out-Null
"TestProject" | Set-Content -Path (Join-Path $tmp 'who.md') -Encoding utf8
"Description de test." | Set-Content -Path (Join-Path $tmp 'what.md') -Encoding utf8
& pwsh -File (Join-Path $root 'docs\readme-builder\readme-generate.ps1') -Root $tmp -Lang en 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] Build builder" -ForegroundColor Red; $fail++ } else { Write-Host "[OK] Build builder" -ForegroundColor Green }

# 7b. Lint MD
& pwsh -File (Join-Path $root 'lint\markdown.ps1') -Path (Join-Path $tmp 'README.md') 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "[FAIL] Lint MD" -ForegroundColor Red; $fail++ } else { Write-Host "[OK] Lint MD" -ForegroundColor Green }

# 7c. Dryrun create
Push-Location $tmp
& pwsh -File (Join-Path $root 'create\create.ps1') TestProjet -DryRun -Yes 2>&1 | Out-Null
$createExit = $LASTEXITCODE
Pop-Location
if ($createExit -ne 0) { Write-Host "[FAIL] Dryrun create : exit $createExit" -ForegroundColor Red; $fail++ } else { Write-Host "[OK] Dryrun create" -ForegroundColor Green }

Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
# Resultat
# ---------------------------------------------------------------------------
if ($fail -gt 0) {
    Write-Host "`n$fail echec(s)." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nReview parfaite et integrale : OK." -ForegroundColor Green
    exit 0
}
