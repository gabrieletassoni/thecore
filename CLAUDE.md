# CLAUDE.md — Thecore Framework Repository

## What This Repository Is

**Thecore** is a documentation and framework scaffolding repository for building modular Ruby on Rails applications using **ATOMS** (Atomic Task-Oriented Modules). This repository is **not a Rails application itself** — it contains:

- Comprehensive developer documentation (`docs/`)
- Sample DevContainer configurations (`samples/devcontainer/`)
- Sample API specifications (`samples/sample_swagger.json`)
- A GitHub Pages deployment workflow

The actual framework gems and tools are published separately and pulled in by generated applications.

---

## Repository Structure

```
thecore/
├── .github/workflows/pages.yml   # GitHub Pages auto-deploy (docs/ → GH Pages)
├── docs/                          # All documentation (deployed via GitHub Pages)
│   ├── SUMMARY.md                # Documentation index / table of contents
│   ├── GUIDE.md                  # Primary developer reference (~870 lines)
│   ├── WALKTHROUGH.md            # Step-by-step tutorial (Fleet Management example)
│   ├── AUTHENTICATION.md         # Auth integrations: Local, LDAP, Google, Entra ID
│   ├── REST_API.md               # REST API reference (JWT, Ransack, filters, uploads)
│   ├── ACTIONCABLE.md            # WebSocket/ActionCable channel documentation
│   ├── SETUP_VSCODE.md           # DevContainer philosophy overview
│   ├── SETUP_VSCODE_LINUX.md     # Ubuntu 24.04 setup instructions
│   ├── SETUP_VSCODE_WINDOWS.md   # Windows 11 + WSL setup instructions
│   ├── SETUP_VSCODE_MACOS.md     # macOS setup instructions
│   ├── index.html                # Documentation landing page (manually maintained)
│   ├── GUIDE.html                # Generated HTML version of GUIDE.md
│   ├── WALKTHROUGH.html          # Generated HTML version of WALKTHROUGH.md
│   └── images/                   # Documentation images
├── samples/
│   ├── Gitignore                 # Template .gitignore for Thecore apps
│   ├── sample_swagger.json       # Full OpenAPI/Swagger spec example
│   ├── devcontainer/             # Sample DevContainer configuration
│   │   ├── devcontainer.json
│   │   ├── docker-compose.yml    # db (PostgreSQL 15), cache (KeyDB), app services
│   │   ├── Dockerfile            # References gabrieletassoni/vscode-devcontainers-thecore:3
│   │   ├── create-db-user.sql
│   │   └── backend.code-workspace
│   └── insomnia/
│       └── ApiV2Tests.json       # Insomnia API test collection
└── README.md                      # Project overview and philosophy
```

---

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
gem 'model_driven_api', '~> 3.1'  # Auto REST API from models
gem 'thecore_ui_rails_admin', '~> 3.2'  # Admin UI theming/enhancements
```

### Three-Concern Model Anatomy

Every model in an ATOM has **three concern files** (fat model via concerns pattern):

| Concern | Module | Purpose |
|---|---|---|
| `concerns/api/model_name.rb` | `Api::ModelName` | JSON serialization for REST API |
| `concerns/rails_admin/model_name.rb` | `RailsAdmin::ModelName` | Admin UI configuration |
| `concerns/endpoints/model_name.rb` | `Endpoints::ModelName` | Custom non-CRUD actions + OpenAPI docs |

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

---

## Authentication System

The authentication stack is layered (all except Local are optional):

1. **Local** (always active) — Devise `database_authenticatable`
   - Password: 8-128 chars, requires uppercase, lowercase, digit, special char
   - Session timeout: 31 minutes (env: `SESSION_TIMEOUT_IN_MINUTES`)

2. **LDAP/Active Directory** — configured via `ldap_servers` DB table; supports LDAPS (port 636)

3. **Google OAuth2** — activated by setting `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET`

4. **Microsoft Entra ID** — activated by setting `ENTRA_CLIENT_ID` + `ENTRA_CLIENT_SECRET` + `ENTRA_TENANT_ID`

---

## REST API Summary

The REST API is provided by the `model_driven_api` gem and is schema-driven (automatic CRUD from models):

- **Authentication:** JWT via `POST /api/v2/authenticate`; token refreshed (sliding expiration) on every successful request
- **Authorization:** CanCanCan-based
- **Filtering:** Ransack predicates; supports pagination and count params
- **HTTP Status Codes:** 200, 401, 403, 404, 422, 500
- **Custom Actions:** Non-CRUD endpoints documented with OpenAPI in `Endpoints::ModelName` concern
- **File Uploads:** ActiveStorage via FormData; deletion via `remove_<attribute>` param
- **Raw SQL:** Simple queries and CTEs supported

See `docs/REST_API.md` for full examples.

---

## WebSocket / ActionCable

Single channel: `ActivityLogChannel`

Built-in message topics (all messages require a `topic` key):
- `general` — keep-alive / subscription confirmation
- `record` — AR record changes (create/update/destroy + validation errors)
- `tcp_debug` — TCP debugging status

See `docs/ACTIONCABLE.md` for Ruby and JavaScript client examples.

---

## CI/CD

### This Repository

`.github/workflows/pages.yml` deploys `docs/` to GitHub Pages on:
- Push to `main` or `release/*`
- Manual dispatch

### Thecore Applications (described in docs)

- **GitLab CI:** `docker-deploy.sh` for Docker image builds
- **GitHub Actions:** Gem publishing for ATOM gems

---

## Development Workflow for This Repo

### Making Documentation Changes

1. Edit files in `docs/` directory
2. Update `docs/SUMMARY.md` if adding/removing files
3. Update `docs/index.html` manually if the landing page needs changes (it is NOT auto-generated from markdown)
4. HTML versions (`GUIDE.html`, `WALKTHROUGH.html`) are generated separately — update markdown source; HTML may need manual regeneration

### Branch & PR Conventions

- Work on feature branches with descriptive names (observed pattern: `claude/<description>-<id>`)
- PRs are merged into `master`
- Commit messages: `docs: <description>` for documentation changes

### No Tests

This repository has no test suite — it is a documentation and scaffolding repo. No `spec/` or `test/` directories exist.

### No Gemfile / No Bundler

This is not a Ruby gem or Rails application. There is no `Gemfile`, `.gemspec`, or `Rakefile` to run.

---

## Key Conventions in Documentation

When writing or updating documentation for this repo, follow these conventions:

### Naming

- **ATOM** — always uppercase, full form is "Atomic Task-Oriented Module"
- **Thecore** — capitalized, not "thecore" or "TheCore"
- **rails_admin**, **devise**, **cancancan** — lowercase, as gem names
- Model concerns: `Api::ModelName`, `RailsAdmin::ModelName`, `Endpoints::ModelName` — note the double-colon namespacing

### File Structure in Docs

- All docs live in `docs/` — do not put docs in the repo root (except README.md and CLAUDE.md)
- No numeric prefixes on filenames (they were removed; see commit `605e01a`)
- Filenames: `UPPERCASE.md` for primary docs, `SETUP_VSCODE_PLATFORM.md` for setup guides

### Content Structure

Each major doc should have:
1. A clear intro explaining what it covers
2. Prerequisites or context
3. Practical examples with code blocks
4. Links to related docs

### Code Blocks

Use fenced code blocks with language tags:
- `ruby` for Ruby/Rails code
- `bash` or `sh` for shell commands
- `json` for JSON/API examples
- `yaml` for YAML configs

---

## Key Files for AI Assistants

When asked to modify or extend documentation:

| Task | File(s) to edit |
|---|---|
| Framework philosophy / architecture | `docs/GUIDE.md`, `README.md` |
| Step-by-step tutorial | `docs/WALKTHROUGH.md` |
| Authentication docs | `docs/AUTHENTICATION.md` |
| REST API docs | `docs/REST_API.md` |
| WebSocket docs | `docs/ACTIONCABLE.md` |
| DevContainer setup | `docs/SETUP_VSCODE*.md` |
| Landing page | `docs/index.html` (hand-edited HTML) |
| Doc index | `docs/SUMMARY.md` |

---

## External Resources

- Framework GitHub org: `https://github.com/thecore-framework` (ATOMs are published here)
- DevContainer image: `gabrieletassoni/vscode-devcontainers-thecore:3` (Docker Hub)
- VS Code extension: Thecore extension (provides "Setup Devcontainer", "Create App", "Create ATOM", "Add Model", etc. commands)
