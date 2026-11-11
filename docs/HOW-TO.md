# How To — Usine à agents (Alpha)

## Vue d'ensemble

Alpha est une usine à agents : PowerShell pur, zéro dépendance. Le Markdown canonique vit dans `ai/agents/`. Les outils (OpenCode, Copilot, Claude Code) reçoivent une version traduite. Le builder génère le `README.md` à partir de la structure réelle du projet.

## Structure du repo

```
Alpha/
├── create/              # Point d'entrée : bootstrappe un projet
│   ├── create.ps1
│   └── extensions/      # Extensions chargées dynamiquement
├── lib/                 # Socle partagé
│   ├── state.ps1        # État global ($State)
│   ├── logging.ps1      # Write-Log, Write-Ok, Write-Err, Die...
│   ├── helpers.ps1      # Invoke-Run, Confirm-YesNo, Test-Command
│   └── readme.ps1       # Primitive du readme-builder
├── ai/agents/           # Samples d'agents (bibliothèque, lecture seule)
├── .opencode/agents/    # Agents déployés (exécution)
├── docs/
│   ├── readme-builder/  # Builder de README
│   │   ├── readme-generate.ps1
│   │   └── i18n/       # Traductions (en, fr, es, ar)
│   └── HOW-TO.md        # Ce fichier
├── lint/                # Outils de vérification
│   ├── markdown.ps1     # Lint/correction Markdown
│   └── powershell.ps1   # Review parfaite et intégrale PowerShell
├── tests/               # (vide, tests dans lint/)
└── README.md            # Généré par le builder
```

## Conventions

- **Source unique** : le Markdown canonique vit dans `ai/agents`. Les outils reçoivent une version traduite.
- **Séparation stricte** : samples = lecture seule, agents déployés = exécution, scripts = outillage.
- **Zéro package** : chaque ligne est justifiée.
- **Racine de confiance** : le schéma définit ce qu'un agent valide doit contenir.

## Utilisation du builder

### Générer le README

```powershell
.\docs\readme-builder\readme-generate.ps1 -Lang en
```

Paramètres :

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `-Root` | Racine du projet à analyser | Racine du repo |
| `-Lang` | Langue (en, fr, es, ar) | en |
| `-OutDir` | Dossier de sortie | Racine du repo |
| `-MaxDepth` | Profondeur de l'arborescence | 3 |
| `-DryRun` | Simule sans écrire | - |
| `-Yes` | Accepte sans demander | - |
| `-LogFile` | Journalise dans un fichier | - |

### Métadonnées du projet

Créer `docs/who.md` (nom du projet) et `docs/what.md` (description). Le builder les lit automatiquement.

### Multilingue

Les traductions sont dans `docs/readme-builder/i18n/<lang>.json`. Si le fichier n'existe pas pour la langue demandée, le builder échoue explicitement.

## Utilisation de create.ps1

```powershell
.\create\create.ps1 MonProjet -Git -GitHub -VsCode -AI
```

Modes :
- `-DryRun` : simule sans effet de bord.
- `-Yes` : tout accepter sans demander.
- `-AI` : importer les agents IA depuis `ai/agents/`.

Hooks : `after_directory`, `after_git`, `after_github`, `after_all`.

Extensions : chargées depuis `create/extensions/` (fichiers `.ps1`).

## Libs

### state.ps1
État global `$State` : Name, Dir, GitLocal, GitHub, GitHubUrl, VsCode, DryRun, AssumeYes, ForceGit, ForceGitHub, ForcePublic, ForceVsCode, ForceAI, ExtensionsDir, LogFile.

### logging.ps1
- `Write-Log`, `Write-Ok`, `Write-Err`, `Write-Info`, `Write-Warn`, `Write-Check`, `Write-Step`
- `Die` : affiche une erreur et quitte.

### helpers.ps1
- `Invoke-Run` : exécute une commande (respecte DryRun).
- `Confirm-YesNo` : demande de confirmation (respecte AssumeYes).
- `Test-Command` : vérifie qu'une commande existe.

### readme.ps1
Primitive du builder : scan, inventaire, sections, slug/TOC, i18n, génération.

## Lint

### Markdown
```powershell
pwsh -File lint/markdown.ps1 -Path README.md
pwsh -File lint/markdown.ps1 -Path README.md -Fix
```

Corrige : MD022 (headings), MD032 (listes), MD060 (tableaux).

### PowerShell
```powershell
pwsh -File lint/powershell.ps1
```

Vérifie : syntaxe, PSScriptAnalyzer, conventions, sécurité, cohérence des libs, documentation, tests fonctionnels.

## Tests

Les tests sont intégrés dans `lint/powershell.ps1` :
- Syntaxe de tous les `.ps1`.
- PSScriptAnalyzer (si installé).
- Build du builder sur un dossier temporaire.
- Lint MD sur le README généré.
- Dryrun de create.ps1.

## Conventions de code

- Fonctions en PascalCase avec verbe-nom (`Write-Log`, `Get-RBRoot`).
- Paramètres en PascalCase (`$Name`, `$Lang`).
- Variables en camelCase (`$root`, `$md`).
- Pas d'`Invoke-Expression`, pas de credentials en clair.
- Pas de chemins codés en dur (utiliser `$PSScriptRoot`).
- Chaque fonction documentée par un commentaire précédent.
- Paramètres typés.

## Philosophie

- Pas de conjecture, pas d'hypothèse.
- Tout est vérifiable, traçable, justifié.
- La complexité doit être justifiée, visible, compréhensible, gouvernable.
- Les outils sont créés, maîtrisés, utilisés consciemment.