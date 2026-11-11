# Documentation workflow and conventions

> Moved verbatim from `CLAUDE.md` on 2026-11-11 (repository structure, development workflow, documentation conventions, key files). `CLAUDE.md` points here; keep this file accurate whenever the behaviour it describes changes.

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
│   ├── REACT_FRONTEND.md         # React frontend reference (thecore-auth library)
│   ├── REACT_FRONTEND_WALKTHROUGH.md # React frontend tutorial (+ .html renderer)
│   ├── SETUP_VSCODE.md           # DevContainer philosophy overview
│   ├── SETUP_VSCODE_LINUX.md     # Ubuntu 24.04 setup instructions
│   ├── SETUP_VSCODE_WINDOWS.md   # Windows 11 + WSL setup instructions
│   ├── SETUP_VSCODE_MACOS.md     # macOS setup instructions
│   ├── index.html                # Documentation landing page (manually maintained)
│   ├── GUIDE.html                # Renders GUIDE.md in the browser (hand-written sidebar TOC)
│   ├── WALKTHROUGH.html          # Renders WALKTHROUGH.md in the browser
│   ├── images/                   # Documentation images
│   ├── adr/                      # Architecture decision records
│   └── agents/                   # Agent topic files CLAUDE.md points to (published too)
├── samples/
│   ├── Gitignore                 # Template .gitignore for Thecore apps
│   ├── CLAUDE.md                 # Agent instructions for a new app (fetched by the App template)
│   ├── AGENTS.md                 # Points agents other than Claude Code to CLAUDE.md
│   ├── ATOM_CLAUDE.md            # CLAUDE.md skeleton for a new ATOM (fetched by thecore:atom)
│   ├── docs/agents/              # issue-tracker (GitHub/GitLab Issues from the git remote), triage-labels, domain
│   ├── .gitlab-ci.yml            # App CI: build/test/lint/deploy + security scanning (SAST, Secret Detection, brakeman, bundler-audit, security-summary)
│   ├── .github/workflows/        # ci.yml (build/test/lint/deploy), security.yml (brakeman, bundler-audit, nightly)
│   ├── script/security_summary.rb # Lists GitLab CE SAST/Secret Detection findings; tested by test/script/security_summary_test.rb
│   ├── sample_swagger.json       # Full OpenAPI/Swagger spec example
│   ├── devcontainer/             # Sample DevContainer configuration
│   │   ├── devcontainer.json
│   │   ├── docker-compose.yml    # db (PostgreSQL 15), cache (KeyDB), app services
│   │   ├── Dockerfile            # References gabrieletassoni/vscode-devcontainers-thecore:3
│   │   ├── create-db-user.sql
│   │   └── backend.code-workspace
│   └── insomnia/
│       └── ApiV2Tests.json       # Insomnia API test collection
├── GLOSSARY.md                    # Domain glossary
└── README.md                      # Project overview and philosophy
```

## Development Workflow for This Repo

### Making Documentation Changes

1. Edit files in `docs/` directory
2. Update `docs/SUMMARY.md` if adding/removing files
3. Update `docs/index.html` manually if the landing page needs changes (it is NOT auto-generated from markdown)
4. HTML versions (`GUIDE.html`, `WALKTHROUGH.html`) are not generated: they `fetch` the markdown file and render it in the browser (`marked`), so a markdown change shows there as is. Only `GUIDE.html`'s sidebar table of contents is hand-written: update it when you add, remove or renumber a `GUIDE.md` section

### Branch & PR Conventions

- Work on feature branches with descriptive names (observed pattern: `claude/<description>-<id>`)
- PRs are merged into `master`
- Commit messages: `docs: <description>` for documentation changes

### No Tests

This repository has no test suite — it is a documentation and scaffolding repo. No `spec/` or `test/` directories exist.

### No Gemfile / No Bundler

This is not a Ruby gem or Rails application. There is no `Gemfile`, `.gemspec`, or `Rakefile` to run.

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
