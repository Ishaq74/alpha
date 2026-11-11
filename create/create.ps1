[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Name,

    [switch]$Yes,
    [switch]$Git,
    [switch]$GitHub,
    [switch]$Public,
    [switch]$VsCode,
    [switch]$DryRun,
    [string]$ExtensionsDir,
    [string]$LogFile
)

# ---------------------------------------------------------------------------
# État
# ---------------------------------------------------------------------------

$State = @{
    Name         = $Name
    Dir          = ""
    GitLocal     = $false
    GitHub       = $false
    GitHubUrl    = ""
    VsCode       = $false
    DryRun       = $DryRun.IsPresent
    AssumeYes    = $Yes.IsPresent
    ForceGit     = $Git.IsPresent
    ForceGitHub  = $GitHub.IsPresent
    ForcePublic  = $Public.IsPresent
    ForceVsCode  = $VsCode.IsPresent
    ExtensionsDir = $ExtensionsDir
    LogFile      = $LogFile
}

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

function Write-Log {
    param(
        [string]$Tag,
        [string]$Message,
        [string]$Color = "White"
    )
    $line = "[$Tag] $Message"
    Write-Host $line -ForegroundColor $Color
    if ($State.LogFile) {
        $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        "$timestamp $line" | Add-Content -Path $State.LogFile -Encoding UTF8
    }
}

function Write-Ok    { Write-Log "OK"     $args[0] "Green" }
function Write-Err   { Write-Log "ERREUR" $args[0] "Red" }
function Write-Info  { Write-Log "INFO"   $args[0] "Cyan" }
function Write-Warn  { Write-Log "WARN"   $args[0] "Yellow" }
function Write-Check { Write-Log "CHECK"  $args[0] "Cyan" }
function Write-Step  { Write-Log "STEP"   $args[0] "Cyan" }

function Die {
    param([string]$Message)
    Write-Err $Message
    exit 1
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Invoke-Run {
    param([scriptblock]$Command)
    if ($State.DryRun) {
        Write-Info "DRY-RUN: $Command"
        return
    }
    & $Command
}

function Ask-YesNo {
    param([string]$Prompt)
    if ($State.AssumeYes) { return $true }
    while ($true) {
        $reply = Read-Host "$Prompt (o/N)"
        switch ($reply.ToLower()) {
            { $_ -in "o", "oui", "y", "yes" } { return $true }
            { $_ -in "n", "non", "no", "" }   { return $false }
            default { Write-Info "Réponds par o ou N." }
        }
    }
}

function Test-Command {
    param([string]$Cmd)
    return [bool](Get-Command $Cmd -ErrorAction SilentlyContinue)
}

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
    $env:CREATE_HAS_GITHUB = $State.GitHub
    $env:CREATE_GITHUB_URL = $State.GitHubUrl
}

function Load-Extensions {
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
    Write-Step "Création du dossier"
    $name = $State.Name

    if (Test-Path $name) {
        if (-not (Test-Path $name -PathType Container)) {
            Die "'$name' existe déjà et n est pas un dossier."
        }
        Write-Warn "Le dossier '$name' existe déjà."
        if (-not (Ask-YesNo "Entrer dans ce dossier ?")) { Die "Annulé." }
    } else {
        Invoke-Run { New-Item -ItemType Directory -Path $name -Force | Out-Null }
        Write-Ok "Dossier créé."
    }

    Set-Location $name
    $State.Dir = (Get-Location).Path
    Write-Ok "Répertoire de travail : $($State.Dir)"
    Invoke-Hooks "after_directory"
}

function Phase-Git {
    Write-Step "Initialisation Git"
    if (-not (Test-Command "git")) {
        Write-Warn "git n est pas disponible."
        return
    }

    if (Test-Path .git) {
        Write-Warn "Un dépôt Git existe déjà."
        if (Ask-YesNo "Supprimer .git et recommencer ?") {
            Invoke-Run { Remove-Item -Recurse -Force .git }
            Write-Ok ".git supprimé."
        }
    }

    if (-not (Test-Path .git)) {
        Invoke-Run { git init -b main }
        if ($LASTEXITCODE -ne 0) { Die "git init a échoué." }
        Write-Ok "Dépôt initialisé."
    }

    if (-not (Test-Path .gitignore)) {
        @"
.DS_Store
.env
.env.*
*.log
.vscode/
node_modules/
__pycache__/
"@ | Invoke-Run { Set-Content -Path .gitignore -Encoding UTF8 }
        Write-Ok ".gitignore créé."
    }

    if (-not (Test-Path README.md)) {
        @"
# $($State.Name)

Créé par create.
"@ | Invoke-Run { Set-Content -Path README.md -Encoding UTF8 }
        Write-Ok "README.md créé."
    }

    Invoke-Run { git add .gitignore README.md 2>$null }
    $status = git diff --cached --quiet 2>$null
    if (-not $State.DryRun -and $LASTEXITCODE -ne 0) {
        git commit -m "Initial commit"
        if ($LASTEXITCODE -ne 0) { Write-Warn "Le commit initial a échoué." }
    }

    if (Test-Path .git) {
        $State.GitLocal = $true
        Write-Ok "Git local prêt."
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
    if ($State.ForcePublic -or (Ask-YesNo "Dépôt public ?")) {
        $visibility = "public"
    }

    $repo = $State.Name

    gh repo view $repo 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Warn "Le dépôt GitHub '$repo' existe déjà."
        if (Ask-YesNo "Le lier comme origin et pousser ?") {
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

Load-Extensions

# Avertissement si déjà dans un dépôt Git
git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Warn "Le répertoire courant est déjà dans un dépôt Git."
    if (-not (Ask-YesNo "Continuer ?")) { Die "Annulé." }
}

Phase-Directory

if ($State.ForceGit -or (Ask-YesNo "Initialiser un dépôt Git local ?")) {
    Phase-Git
}

if ($State.GitLocal -and ($State.ForceGitHub -or (Ask-YesNo "Créer le dépôt sur GitHub ?"))) {
    Phase-GitHub
}

if ($State.ForceVsCode -or (Ask-YesNo "Ouvrir dans VS Code ?")) {
    Phase-VsCode
}

Phase-Summary