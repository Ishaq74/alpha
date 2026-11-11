# Alpha

## What

Usine a agents. PowerShell pur, zero dependance.

## Table of Contents

- [What](#what)

- [Structure](#structure)

- [Commands](#commands)

# AI Agents

Reserve de samples et agents deployes.

# Project Creation

Bootstrap d'un projet : git, github, vscode, extensions.

# Database

Base de donnees, schemas, migrations, seeds.

# Shared Core

Socle partage : state, logging, helpers, readme.

# Email & SMTP

Fournisseurs, templates, commandes.

# Tests

Tests PowerShell et verification.

## Structure

``nai/
  agents/
    alpha.md
    ishaq.agent.md
  README.md
create/
  extensions/
    readme.ps1
  create.ps1
  README.md
database/
  commands/
    _migration-sql.ts
    _utils.ts
    db.check.ts
    db.clean-media.ts
    db.cleanup-audit.ts
    db.compare.ts
    db.generate.ts
    db.infra.ts
    db.migrate.ts
    db.reset.ts
    db.seed-media.ts
    db.seed.ts
    db.sync.ts
  data/
  infra/
    mysql/
    postgres/
    sqlite/
    00-functions.sql
    01-triggers.sql
    02-indexes.sql
    03-constraints.sql
  loaders/
  migrations/
  schemas/
  cache.ts
  drizzle.ts
  env.ts
  README.md
  schemas.ts
docs/
  readme-builder/
    i18n/
      ar.json
      en.json
      es.json
      fr.json
    readme-generate.ps1
  README.md
  what.md
  who.md
lib/
  helpers.ps1
  logging.ps1
  README.md
  readme.ps1
  state.ps1
smtp/
  commands/
    _utils.ts
    logs.rotate.ts
    smtp.check.ts
  providers/
    brevo.ts
    nodemailer.ts
    resend.ts
  templates/
    blog-newsletter.ts
    contact-form.ts
    delete-account.ts
    i18n.ts
    layout.ts
    organization-invitation.ts
    reset-password.ts
    verify-email.ts
  env.ts
  README.md
  send.ts
  types.ts
tests/
  ps1.ps1
  README.md
README.fr.md
README.md
``n

## Commands

| Command | Description |
| --- | --- |
| `./create/create.ps1` | PowerShell script |


