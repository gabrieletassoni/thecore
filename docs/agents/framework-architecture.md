# Thecore framework (what the docs describe)

> Moved verbatim from `CLAUDE.md` on 2026-11-11 (framework architecture, gem stack, model anatomy, Docker services and images, authentication, REST API, ActionCable, CI/CD, external resources). `CLAUDE.md` points here; keep this file accurate whenever the behaviour it describes changes.

## Framework Architecture (What Thecore Apps Look Like)

Understanding what this documentation describes is essential for working on it accurately.

### ATOMS — The Core Concept

An ATOM (Atomic Task-Oriented Module) is a **Rails engine packaged as a Git submodule** under `vendor/submodules/` in a Thecore application. Each ATOM:
- Encapsulates a domain (e.g., "Vehicle Registry", "User Management")
- Contains its own migrations, models, concerns, and routes
- Is independently versioned and reusable across projects

### Standard Gem Stack

Generated Thecore applications use:
```ruby
gem 'rails_admin'       # Admin UI
gem 'devise'            # Authentication base
gem 'cancancan'         # Authorization
gem 'model_driven_api', '~> 3.13', '>= 3.13.1'  # Auto REST API from models
gem 'thecore_ui_rails_admin', '~> 3.8', '>= 3.8.7'  # Admin UI theming/enhancements
gem 'thecore_generators', '~> 3.13', group: :development  # Generators (see the App template)
```

### Model Anatomy

A model gets its default API serialization and admin navigation from `ApplicationRecord` (ADR
0001): none of these files exists until the model needs to differ.

| File | Module | Purpose |
|---|---|---|
| `concerns/api/model_name.rb` | `Api::ModelName` | JSON serialization overrides for the REST API |
| `concerns/rails_admin/model_name.rb` | `RailsAdmin::ModelName` | Admin UI configuration overrides |
| `app/models/endpoints/model_name.rb` + an initializer | `Endpoints::ModelName` (`< NonCrudEndpoints`) | Custom non-CRUD actions + OpenAPI docs, added with `class_eval` inside `after_initialize` (never `include`) |

### Docker Services

Production/development deployments run four Docker services:
- `db` — PostgreSQL 15-bookworm
- `cache` — KeyDB (Redis-compatible)
- `backend` — Rails application
- `worker` — Sidekiq background jobs

### Version Scheme

`<major>.<year>.<month>.<day>` (e.g., `3.2026.03.21`)

### Three Docker Images

| Image | Purpose |
|---|---|
| `gabrieletassoni/thecore-common` | Base image |
| `gabrieletassoni/thecore` | Production |
| `gabrieletassoni/vscode-devcontainers-thecore` | Development DevContainer |

## Authentication System

The authentication stack is layered (all except Local are optional):

1. **Local** (always active) — Devise `database_authenticatable`
   - Password: 8-128 chars, requires uppercase, lowercase, digit, special char
   - Session timeout: 31 minutes (env: `SESSION_TIMEOUT_IN_MINUTES`)

2. **LDAP/Active Directory** — configured via `ldap_servers` DB table; supports LDAPS (port 636)

3. **Google OAuth2** — activated by setting `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET`

4. **Microsoft Entra ID** — activated by setting `ENTRA_CLIENT_ID` + `ENTRA_CLIENT_SECRET` + `ENTRA_TENANT_ID`

## REST API Summary

The REST API is provided by the `model_driven_api` gem and is schema-driven (automatic CRUD from models):

- **Authentication:** JWT via `POST /api/v2/authenticate`; token refreshed (sliding expiration) on every successful request
- **Authorization:** CanCanCan-based
- **Filtering:** Ransack predicates; supports pagination and count params
- **HTTP Status Codes:** 200, 401, 403, 404, 422, 500
- **Custom Actions:** Non-CRUD endpoints documented with OpenAPI on the `Endpoints::ModelName` class (`class_eval` in `after_initialize`, GUIDE §5)
- **File Uploads:** ActiveStorage via FormData; deletion via `remove_<attribute>` param
- **Raw SQL:** Simple queries and CTEs supported

See `docs/REST_API.md` for full examples.

## WebSocket / ActionCable

Single channel: `ActivityLogChannel`

Built-in message topics (all messages require a `topic` key):
- `general` — keep-alive / subscription confirmation
- `record` — AR record changes (create/update/destroy + validation errors)
- `tcp_debug` — TCP debugging status

See `docs/ACTIONCABLE.md` for Ruby and JavaScript client examples.

## CI/CD

### This Repository

`.github/workflows/pages.yml` deploys `docs/` to GitHub Pages on:
- Push to `main` or `master`
- Manual dispatch

### Thecore Applications (described in docs)

- **App CI** (`samples/.gitlab-ci.yml`, `samples/.github/workflows/ci.yml`): build (`app-compile.sh`), test, lint and deploy (`docker-deploy.sh`, reading the committed `vendor/deploytargets/`) on a `version` bump; security scanning on every push and nightly
- **ATOM CI** (written by `thecore:atom`): `gempush.yml` publishes to RubyGems.org from `release/3`; GitLab's `build_gem` publishes when `lib/*/version.rb` changes

## External Resources

- Framework GitHub account: `https://github.com/gabrieletassoni` (base ATOMs live here; spot gems are on Bancolini GitLab)
- DevContainer image: `gabrieletassoni/vscode-devcontainers-thecore:3` (Docker Hub)
- VS Code extension: Thecore extension (provides "Setup Devcontainer", "Create App", "Create ATOM", "Add Model", etc. commands)
