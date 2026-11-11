# i18n.ps1 — chaînes du README, deux langues : en, fr
# Ajouter une langue = ajouter une entrée dans $Langs et ses traductions.

$Langs = @('en', 'fr')

$I18n = @{
    projectName = @{ en = 'Alpha'; fr = 'Alpha' }
    description = @{
        en = 'A universal project bootstrap and operations toolkit. Pure PowerShell core, zero dependencies, presence-based detection.'
        fr = 'Un outil universel de bootstrap et d''opérations de projet. Cœur en PowerShell pur, zéro dépendance, détection par présence.'
    }
    subtitle = @{
        en = 'Create projects, validate agents, manage databases, send email — each primitive is a tool, a check, and a test at once.'
        fr = 'Créer des projets, valider des agents, gérer des bases, envoyer des emails — chaque primitive est à la fois un outil, un check et un test.'
    }
    toc = @{ en = 'Table of Contents'; fr = 'Sommaire' }
    sections = @{
        overview      = @{ en = 'Overview'; fr = 'Vue d''ensemble' }
        techStack     = @{ en = 'Tech Stack'; fr = 'Stack technique' }
        gettingStarted = @{ en = 'Getting Started'; fr = 'Démarrage' }
        designSystem  = @{ en = 'Design System'; fr = 'Design System' }
        database      = @{ en = 'Database'; fr = 'Base de données' }
        authentication = @{ en = 'Authentication & Security'; fr = 'Authentification et sécurité' }
        content       = @{ en = 'Content & CMS'; fr = 'Contenu et CMS' }
        media         = @{ en = 'Media'; fr = 'Médias' }
        email         = @{ en = 'Email & Notifications'; fr = 'Email et notifications' }
        internationalisation = @{ en = 'Internationalisation'; fr = 'Internationalisation' }
        cicd          = @{ en = 'CI/CD & Quality'; fr = 'CI/CD et qualité' }
    }
    subsections = @{
        prerequisites = @{ en = 'Prerequisites'; fr = 'Prérequis' }
        installation  = @{ en = 'Installation'; fr = 'Installation' }
        envVars       = @{ en = 'Environment Variables'; fr = 'Variables d''environnement' }
        aliasTs       = @{ en = 'TypeScript Aliases'; fr = 'Alias TypeScript' }
    }
}

function Get-RBI18n {
    param([string]$Section, [string]$Lang = 'en')
    if ($I18n.ContainsKey($Section) -and $I18n[$Section].ContainsKey($Lang)) {
        return $I18n[$Section][$Lang]
    }
    return ''
}
