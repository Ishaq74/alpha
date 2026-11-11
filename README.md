# Alpha

Usine à agents. PowerShell pur, zéro dépendance.

## Structure

```
Alpha/
├── create/create.ps1      # Point d'entrée : bootstrappe un projet
├── lib/                   # Socle partagé
│   ├── state.ps1          # État global
│   ├── logging.ps1        # Write-Log, Write-Ok, Die...
│   └── helpers.ps1        # Invoke-Run, Ask-YesNo, Test-Command
├── ai/agents/             # Samples d'agents (bibliothèque)
│   ├── alpha.md
│   └── ishaq.agent.md
└── .opencode/agents/      # Agents déployés (ce qui tourne)
    └── alpha.md
```

## Philosophie

- **Source unique** : le Markdown canonique vit dans `ai/agents`. Les outils (OpenCode, Copilot, Claude Code...) reçoivent une version traduite.
- **Racine de confiance** : le schéma définit ce qu'un agent valide doit contenir. Rien n'est accidentel.
- **Séparation stricte** : samples = lecture seule, agents déployés = exécution, scripts = outillage.
- **Zéro package** : chaque ligne est justifiée. Si un besoin force un autre langage, on le saura parce que PowerShell aura atteint sa limite.

## create.ps1

Crée un dossier, l'initialise en Git, le pousse sur GitHub, ouvre VS Code. Hooks : `after_directory`, `after_git`, `after_github`, `after_all`. Extensions chargées depuis un dossier `extensions/`.

```powershell
./create/create.ps1 MonProjet -Git -GitHub -VsCode
```

Modes : `-DryRun` pour simuler, `-Yes` pour tout accepter sans demander.

## lib/

Socle réutilisable par tous les futurs scripts — create-agent, check-agent-context, et au-delà.

## ai/agents

La réserve de samples. Fakir et les autres. À utiliser ou ignorer, c'est ton problème.

## .opencode/agents

Ce qui tourne vraiment. Séparé des samples pour ne jamais les confondre.
