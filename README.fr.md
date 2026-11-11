# Alpha
## Description

Usine a agents. PowerShell pur, zero dependance.

## Table des matieres

- [Description](#description)
- [Agents IA](#agents-ia)
- [Creation du projet](#creation-du-projet)
- [Base de donnees](#base-de-donnees)
- [Noyau partage](#noyau-partage)
- [Email et SMTP](#email-et-smtp)
- [Tests](#tests)
- [Structure](#structure)
- [Commandes](#commandes)

## Agents IA

- `agents/`

## Creation du projet

- `extensions/`
- `create.ps1`

## Base de donnees

| Command | Description |
| --------- | ------------- |
| `database/cache.ts` | |
| `database/drizzle.ts` | |
| `database/env.ts` | |
| `database/schemas.ts` | |

**ORM :** `drizzle.ts`**Infrastructure :**
- `mysql/`
- `postgres/`
- `sqlite/`
- `00-functions.sql`
- `01-triggers.sql`
- `02-indexes.sql`
- `03-constraints.sql`

``ncommands/
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
schemas.ts
``n
## Noyau partage

- `helpers.ps1`
- `logging.ps1`
- `readme.ps1`
- `state.ps1`

## Email et SMTP

- `commands/`
- `providers/`
- `templates/`
- `env.ts`
- `send.ts`
- `types.ts`

## Tests

- `ps1.ps1`

## Structure

``nai/
  agents/
    alpha.md
    ishaq.agent.md
create/
  extensions/
    readme.ps1
  create.ps1
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
  send.ts
  types.ts
tests/
  ps1.ps1
README.md
``n
## Commandes

| Command | Description |
|---------|-------------|
| `./create/create.ps1` | PowerShell script |


