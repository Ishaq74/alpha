[CmdLetBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Name,

    [switch]$Yes,
    [switch]$Git,
    [switch]$GitHub,
    [switch]$Public,
    [switch]$VsCode,
    [switch]$AI,
    [switch]$DryRun,
    [string]$ExtensionsDir,
    [string]$LogFile
)
$null = $Name
$null = $Yes
$null = $Git
$null = $GitHub
$null = $Public
$null = $VsCode
$null = $AI
$null = $DryRun
$null = $ExtensionsDir
$null = $LogFile

# ---------------------------------------------------------------------------
# Socle partagé
# ---------------------------------------------------------------------------

. (Join-Path $PSScriptRoot "..\lib\state.ps1")
. (Join-Path $PSScriptRoot "..\lib\logging.ps1")
. (Join-Path $PSScriptRoot "..\lib\helpers.ps1")

# ---------------------------------------------------------------------------
# Extensions
# Hooks : after_directory, after_git, after_github, after_all
# Une extension appelle Register-Hook "after_git" { ... }
# ---------------------------------------------------------------------------

$Hooks = @{
    after_directory = @()
    after_git       = @()
    after_github    = @()
    after_all       = @()
}

function Register-Hook {
    param(
        [string]$Phase,
        [scriptblock]$Action
    )
    if (-not $Hooks.ContainsKey($Phase)) {
        Write-Warn "Hook inconnu : $Phase"
        return
    }
    $Hooks[$Phase] += $Action
}

function Export-State {
    $env:CREATE_NAME       = $State.Name
    $env:CREATE_DIR        = $State.Dir
    $env:CREATE_HAS_GIT    = $State.GitLocal
    $env:CREATE_HAS_GHUB   = $State.GitHub
    $env:CREATE_GHUB_URL   = $State.GitHubUrl
}

function Load-Extension {
    $dir = $State.ExtensionsDir
    if (-not $dir) {
        $dir = Join-Path (Split-Path -Parent $PSCommandPath) "extensions"
    }
    if (-not (Test-Path $dir)) { return }

    Write-Step "Chargement des extensions"
    Get-ChildItem -Path $dir -Filter *.ps1 | ForEach-Object {
        Write-Info "Chargement de $($_.FullName)"
        try {
            . $_.FullName
        } catch {
            Write-Warn "Échec du chargement de $($_.Name) : $_"
        }
    }
}

function Invoke-Hooks {
    param([string]$Phase)
    Export-State
    foreach ($action in $Hooks[$Phase]) {
        Write-Info "Exécution d un hook $Phase"
        if (-not $State.DryRun) {
            try { & $action } catch { Write-Warn "Hook échoué : $_" }
        }
    }
}

# ---------------------------------------------------------------------------
# Phases
# ---------------------------------------------------------------------------

function Phase-Directory {
    Write-Step "Creation du dossier"
    $name = $State.Name
    $target = Join-Path (Get-Location).Path $name

    if (Test-Path $target) {
        if (-not (Test-Path $target -PathType Container)) {
            Die "'$name' existe deja et n est pas un dossier."
        }
        Write-Warn "Le dossier '$name' existe deja."
        if (-not (Confirm-YesNo "Entrer dans ce dossier ?")) { Die "Annule." }
    } else {
        Invoke-Run { New-Item -ItemType Directory -Path $target -Force | Out-Null }
        Write-Ok "Dossier cree."
    }

    if (-not $State.DryRun) {
        Set-Location $target
        $State.Dir = (Get-Location).Path
    } else {
        $State.Dir = $target
        Write-Info "DRY-RUN: repertoire cible : $($State.Dir)"
    }
    Write-Ok "Repertoire de travail : $($State.Dir)"
    Invoke-Hooks "after_directory"
}

function Phase-Git {
    if (-not (Test-Command "git")) {
        Write-Warn "git n est pas disponible."
        return
    }

    $dir = $State.Dir
    $gitDir = Join-Path $dir ".git"

    if (Test-Path $gitDir) {
        Write-Warn "Un depot Git existe deja."
        if (Confirm-YesNo "Supprimer .git et recommencer ?") {
            Invoke-Run { Remove-Item -Recurse -Force $gitDir }
            Write-Ok ".git supprime."
        }
    }

    if (-not (Test-Path $gitDir)) {
        if (-not $State.DryRun) { Push-Location $dir }
        Invoke-Run { git init -b main }
        if (-not $State.DryRun) {
            if ($LASTEXITCODE -ne 0) { Pop-Location; Die "git init a echoue." }
            Pop-Location
        }
        Write-Ok "Depot initialise."
    }

    $gitignore = Join-Path $dir ".gitignore"
    if (-not (Test-Path $gitignore)) {
        $content = ".DS_Store`n.env`n.env.*`n*.log`n.vscode/`nnode_modules/`n__pycache__/`n"
        Invoke-Run { Set-Content -Path $gitignore -Value $content -Encoding UTF8 }
        Write-Ok ".gitignore cree."
    }

    $readme = Join-Path $dir "README.md"
    if (-not (Test-Path $readme)) {
        $content = "# $($State.Name)`n`nCree par create.`n"
        Invoke-Run { Set-Content -Path $readme -Value $content -Encoding UTF8 }
        Write-Ok "README.md cree."
    }

    if (-not $State.DryRun) {
        Push-Location $dir
        Invoke-Run { git add .gitignore README.md 2>$null }
        git diff --cached --quiet 2>$null
        if ($LASTEXITCODE -ne 0) {
            git commit -m "Initial commit" 2>$null
            if ($LASTEXITCODE -ne 0) { Write-Warn "Le commit initial a echoue." }
        }
        Pop-Location
    }

    if (Test-Path $gitDir) {
        $State.GitLocal = $true
        Write-Ok "Git local pret."
        Invoke-Hooks "after_git"
    }
}
function Phase-GitHub {
    Write-Step "Création GitHub"
    if (-not $State.GitLocal) { return }
    if (-not (Test-Command "gh")) {
        Write-Warn "gh n est pas disponible."
        return
    }
    gh auth status 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "gh n est pas authentifié."
        return
    }

    $visibility = "private"
    if ($State.ForcePublic -or (Confirm-YesNo "Dépôt public ?")) {
        $visibility = "public"
    }

    $repo = $State.Name

    gh repo view $repo 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Warn "Le dépôt GitHub '$repo' existe déjà."
        if (Confirm-YesNo "Le lier comme origin et pousser ?") {
            $url = gh repo view $repo --json url -q .url
            Invoke-Run { git remote remove origin 2>$null }
            Invoke-Run { git remote add origin "$url.git" }
            Invoke-Run { git push -u origin main }
        } else {
            return
        }
    } else {
        $ok = Invoke-Run { gh repo create $repo --$visibility --source=. --remote=origin --push }
        if (-not $ok -and -not $State.DryRun) {
            Write-Err "La création du dépôt GitHub a échoué."
            return
        }
    }

    # Vérification réelle du remote
    if (-not $State.DryRun) {
        $remote = git remote get-url origin 2>$null
        if ($remote) {
            git ls-remote --exit-code $remote 2>$null
            if ($LASTEXITCODE -eq 0) {
                $State.GitHub = $true
                $State.GitHubUrl = $remote
                Write-Ok "Dépôt GitHub vérifié : $remote"
                Invoke-Hooks "after_github"
            } else {
                Write-Warn "Le remote n est pas joignable."
            }
        }
    }
}

function Phase-AI {
    Write-Step "Import des agents IA"
    $src = Join-Path (Split-Path -Parent $PSCommandPath) "..\..\ai\agents"
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Warn "Dossier ai/agents introuvable : $src"
        return
    }
    $dst = Join-Path $State.Dir ".opencode\agents"
    Invoke-Run { New-Item -ItemType Directory -Path $dst -Force | Out-Null }
    Get-ChildItem -Path $src -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object {
        $target = Join-Path $dst $_.Name
        if (-not $State.DryRun) {
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
            Write-Ok "Agent importe : $($_.Name)"
        } else {
            Write-Info "DRY-RUN: copie $($_.FullName) -> $target"
        }
    }
}

function Phase-VsCode {
    Write-Step "Ouverture VS Code"
    if (-not (Test-Command "code")) {
        Write-Warn "La commande code n est pas disponible."
        return
    }
    Invoke-Run { code . }
    $State.VsCode = $true
    Write-Ok "VS Code ouvert."
}

function Phase-Summary {
    Write-Step "Résumé"
    Write-Host ""
    Write-Info "Dossier  : $($State.Dir)"
    Write-Info "Git      : $($State.GitLocal)"
    Write-Info "GitHub   : $($State.GitHub)"
    if ($State.GitHubUrl) { Write-Info "URL      : $($State.GitHubUrl)" }
    Write-Info "VS Code  : $($State.VsCode)"
    Write-Host ""
    Write-Info "Commandes :"
    Write-Info "  cd `"$($State.Dir)`""
    if ($State.GitLocal) { Write-Info "  git status" }
    if ($State.GitHub)   { Write-Info "  gh repo view $($State.Name)" }
    Write-Ok "Terminé."
    Invoke-Hooks "after_all"
}

# ---------------------------------------------------------------------------
# Point d entrée
# ---------------------------------------------------------------------------

Write-Info "Démarrage"

if ($State.LogFile) {
    if (Test-Path $State.LogFile) { Clear-Content $State.LogFile }
    Write-Info "Journal : $($State.LogFile)"
}

if (-not $State.Name) {
    $State.Name = Read-Host "Nom du dossier"
}
if ($State.Name -notmatch '^[a-zA-Z0-9._-]{1,64}$') {
    Die "Nom invalide. Autorisé : lettres, chiffres, . _ - (1-64 caractères)."
}

Load-Extension

# Avertissement si déjà dans un dépôt Git
git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Warn "Le répertoire courant est déjà dans un dépôt Git."
    if (-not (Confirm-YesNo "Continuer ?")) { Die "Annulé." }
}

Phase-Directory

if ($State.ForceGit -or (Confirm-YesNo "Initialiser un dépôt Git local ?")) {
    Phase-Git
}

if ($State.GitLocal -and ($State.ForceGitHub -or (Confirm-YesNo "Créer le dépôt sur GitHub ?"))) {
    Phase-GitHub
}

if ($State.ForceVsCode -or (Confirm-YesNo "Ouvrir dans VS Code ?")) {
    Phase-VsCode
}

if ($State.ForceAI -or (Confirm-YesNo "Importer les agents IA ?")) {
    Phase-AI
}

Phase-Summary


