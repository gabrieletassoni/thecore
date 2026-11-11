# CLAUDE.md — Thecore Framework Repository

**Thecore** is a documentation and framework scaffolding repository for building modular Ruby on Rails applications using **ATOMS** (Atomic Task-Oriented Modules). It is **not a Rails application itself**: it holds the developer docs (`docs/`, published to GitHub Pages), the samples the App template and the `thecore:atom` generator fetch (`samples/`), and the Pages workflow. The framework gems and tools are published separately.

## Where things are

```
docs/            developer docs (GUIDE, WALKTHROUGH, AUTHENTICATION, REST_API, ACTIONCABLE, REACT_FRONTEND*,
                 SETUP_VSCODE*), SUMMARY.md (index), index.html (hand-edited landing page),
                 GUIDE.html/WALKTHROUGH.html (render the .md in the browser), images/, adr/, agents/
samples/         files fetched by generated apps/ATOMs: CLAUDE.md, ATOM_CLAUDE.md, AGENTS.md, docs/agents/,
                 .gitlab-ci.yml, .github/workflows/, script/ + test/, devcontainer/, sample_swagger.json, insomnia/
.github/workflows/pages.yml   deploys docs/ to GitHub Pages on every push to main/master (and manual dispatch)
GLOSSARY.md  README.md
```

## Read before working on…

| Topic | File |
| --- | --- |
| Full repository tree, doc-change workflow, branch/PR conventions, writing conventions, which file to edit for which task | `docs/agents/documentation-workflow.md` |
| What the docs describe: ATOMs, gem stack, model anatomy, Docker services/images, version scheme, auth, REST API, ActionCable, app/ATOM CI, external resources | `docs/agents/framework-architecture.md` |
| Security scanning (CodeQL, secret push protection, Dependabot) | `docs/agents/security-scanning.md` |
| Issues (GitHub), triage labels, glossary/ADR layout | `docs/agents/issue-tracker.md`, `triage-labels.md`, `domain.md` |

`docs/agents/` is published with the rest of `docs/` but is not linked from `index.html` or `SUMMARY.md`; keep it that way.

## Rules for every change

- Making documentation changes:
  1. Edit files in `docs/` directory
  2. Update `docs/SUMMARY.md` if adding/removing files
  3. Update `docs/index.html` manually if the landing page needs changes (it is NOT auto-generated from markdown)
  4. HTML versions (`GUIDE.html`, `WALKTHROUGH.html`) are not generated: they `fetch` the markdown file and render it in the browser (`marked`), so a markdown change shows there as is. Only `GUIDE.html`'s sidebar table of contents is hand-written: update it when you add, remove or renumber a `GUIDE.md` section
- All docs live in `docs/` — do not put docs in the repo root (except README.md and CLAUDE.md)
- No numeric prefixes on filenames; `UPPERCASE.md` for primary docs, `SETUP_VSCODE_PLATFORM.md` for setup guides.
- Fenced code blocks always carry a language tag (`ruby`, `bash`/`sh`, `json`, `yaml`).
- Naming: **ATOM** always uppercase; **Thecore** capitalized, not "thecore" or "TheCore"; gem names lowercase (**rails_admin**, **devise**, **cancancan**); concerns `Api::ModelName`, `RailsAdmin::ModelName`, `Endpoints::ModelName`.
- Custom non-CRUD endpoints in the docs are added with `class_eval` inside `after_initialize`, never `include`.
- Commit messages: `docs: <description>`; PRs are merged into `master`.
- No tests, no `Gemfile`, `.gemspec` or `Rakefile`: there is nothing to run or bundle here.
- `samples/` files are fetched from `master` on GitHub by generated apps and ATOMs: a change there reaches every new app.
- When behaviour or structure described here changes, update `CLAUDE.md` or the `docs/agents` file it points to in the same change.
- Secret scanning with push protection rejects a push containing a recognised secret. If it fires on a real secret, remove it from the commit and rotate the secret; never bypass it.

## Agent skills

### Issue tracker

Tasks, issues, bugs, tickets and specs for this repository live **only** in its GitHub Issues
(`gabrieletassoni/thecore`), handled with the `gh` CLI. See `docs/agents/issue-tracker.md`.

**Mandatory rule.** Whenever a skill or development work creates, reads, updates, comments on,
assigns, blocks or closes a task, issue, bug, ticket or spec (for example /to-tickets, /to-spec,
/triage, /wayfinder, /implement, /diagnosing-bugs, /code-review, closing a piece of work, a bug found
during a session), do it in this repository's GitHub Issues following `docs/agents/issue-tracker.md`.
Never use Odoo, `.scratch/` or local Markdown files as a tracker: Odoo is only for the repositories
on Bancolini's GitLab. `#123` means a GitHub issue number of this repository. If `gh` doesn't work,
stop and say so instead of falling back to another tracker.

### Triage labels

The five canonical triage roles map to GitHub labels with the same name (`needs-triage`,
`needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root, created lazily when the first
term or decision is resolved. See `docs/agents/domain.md`.

### Skills

Matt Pocock's skills come from the `mattpocock-skills` Claude Code plugin installed on the
developer's **host** (`claude plugins install mattpocock-skills`, official marketplace), never
vendored here: no `.agents/skills/`, `.claude/commands/` or `skills-lock.json`. Its `ask-matt` skill
maps how the skills connect.
