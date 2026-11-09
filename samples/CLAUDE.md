# CLAUDE.md — <!-- TODO: project/app name -->

<!--
  TODO: One or two sentences describing what this application does and who
  it's for. See docs/GUIDE.md §1 ("Philosophy") in the thecore repo for the
  conventions this file assumes — don't restate them here, link to them.
-->

## Project overview

<!-- TODO: Rails version, Ruby version, database, authentication/authorization
     stack, background jobs, and any other framework-level facts specific to
     this app. -->

## Repository structure

<!-- TODO: this app's own directory layout beyond the generic Rails/Thecore
     skeleton (docs/GUIDE.md §1 in the thecore repo covers the universal
     conventions — link there, don't restate them here) — which ATOMs live
     under vendor/submodules/ and what each owns, any host-app-only lib/
     services, non-standard config/initializers/ files, and so on. -->

## Changing an ATOM

Every change to an ATOM (a `thecore_*` base gem or one of this app's own engines) is made in its
`vendor/submodules/<name>` checkout and released, never patched in the installed gem nor worked
around from this app:

1. Edit and test in the submodule.
2. Bump its version and push to its `release/3`, which publishes it: to RubyGems.org, or to the
   private gem server its gemspec's `allowed_push_host` names.
3. Wait until the new version is on the gem server.
4. Run `bundle update <gem> --conservative` here.
5. Commit the new `Gemfile.lock` together with the moved submodule pointer.

An ATOM not cloned here yet is added first as a submodule on its release branch:
`git submodule add -b release/3 <git url> vendor/submodules/<name>`, committed with the change that
needed it. A new ATOM (`rails generate thecore:atom NAME`) starts as a `path:` entry in the
`Gemfile`; once its first version is published, replace that entry with the published gem and its
version constraint, so this app builds from the gem server like every other ATOM.

## Key domain models

<!-- TODO: this app's own models and how they relate to each other. Nothing
     universal to say here — every Thecore app's domain is different. -->

## Claude Code skills

Matt Pocock's skill set is installed as the `mattpocock-skills` Claude Code plugin, on each
developer's own **host** machine (outside the devcontainer):

```bash
claude plugins install mattpocock-skills
```

(official Claude Code marketplace — nothing to add first; updates arrive automatically. See
https://github.com/mattpocock/skills.) `.devcontainer/devcontainer.json` bind-mounts the host's
`~/.claude` directory into the container wholesale (see `mounts`), so any plugin installed and
enabled on the host — `mattpocock-skills` included — is automatically visible inside the
devcontainer; `.devcontainer/check-plugins.sh`, run from `postCreateCommand`, prints a
non-blocking warning (never fails the build) if it isn't installed/enabled on the host. There is
no repo-level fallback: a machine or agent without the plugin on its host simply doesn't get
these skills.

Claude Code's own plugin registry bakes in absolute host paths rather than `$HOME`-relative ones,
so the bind mount alone isn't sufficient whenever the host username differs from the
devcontainer's `vscode` user (i.e. for every developer) — every marketplace plugin reports
`failed to load: cache-miss` otherwise. `.devcontainer/link-host-home.sh`, also run from
`postCreateCommand` (before `check-plugins.sh`), symlinks `/home/<host-username> -> /home/vscode`
so those absolute paths resolve.

The host paths behind the bind mounts (`~/.claude`, `~/.claude.json`, `~/.bundle`, `~/.gem`) are
created on the host by `initializeCommand` when missing, before it heals stale containers, so a
fresh machine never fails to start the container on a missing mount source. A mount you add or
uncomment in `mounts` needs its host path added there too.

**Several GitHub accounts.** The container has no SSH keys or `~/.ssh/config` of its own: it uses
the keys the host's SSH agent forwards, and GitHub identifies the user by the first key offered,
so a developer with two accounts (e.g. a work and a personal one) got `Permission ... denied to
<first account>` pushing to the other account's repositories. `.devcontainer/github-accounts.sh`,
also run from `postCreateCommand`, asks GitHub which account each agent key belongs to and makes
git use that key for remotes under that account (`git@github.com:<account>/...`, via `includeIf
"hasconfig:remote.*.url:..."` in `~/.config/git/`, since VS Code rewrites `~/.gitconfig` on every
start). Nothing is hardcoded and other remotes are untouched. `gh` is separate: its config mount
is commented out by default; once uncommented, a token the host keeps in its system keyring isn't
reachable from the container, so `gh` reports it invalid here unless that account logged in on
the host with `gh auth login --insecure-storage`.

`ask-matt`'s own SKILL.md (inside the plugin) is the authoritative map of how the skills connect
(main flow, on-ramps, standalone).

**User-invoked only** (`disable-model-invocation: true`: Claude's Skill tool can't trigger them, so
ask the developer to type the `/skill-name` command): `ask-matt`, `grill-with-docs`, `grill-me`,
`to-spec`, `to-tickets`, `triage`, `handoff`, `improve-codebase-architecture`, `teach`,
`to-questionnaire`, `wait-what`, `implement`, `wayfinder`, `setup-matt-pocock-skills`.

**Model-invocable** (Claude invokes them directly when they fit the task): `grilling`,
`domain-modeling`, `codebase-design`, `tdd`, `prototype`, `diagnosing-bugs`, `research`,
`code-review`, `resolving-merge-conflicts`, `wizard`, `writing-for-agents`.

The tracker, labels and domain docs these skills use are already configured (see "Agent skills"),
so `/setup-matt-pocock-skills` is needed only to change them.

## Development workflow

### Required skill sequence for new features and codebase changes

**Before any new implementation request or brainstorming session**, `/ask-matt` should run first
with the request verbatim. Because `ask-matt` has `disable-model-invocation: true`, Claude cannot
invoke it automatically — it must instead prompt the developer to run `/ask-matt` themselves
before proceeding, rather than skip straight to implementation or brainstorming.

**Before writing any code**, follow the flow `/ask-matt` returns — it routes to the correct skill
sequence based on the situation.

- **Update this file** whenever you add or modify a feature, model, endpoint, lib service, or
  integration behaviour. Keep descriptions accurate — stale docs cause incorrect future edits.
- **Update README.md** whenever user-facing setup steps, environment variables, external
  dependencies, or deployment instructions change.
- **Add or update tests** for every change. New functionality must have test coverage; modified
  behaviour must have its existing tests updated to match.

## Code conventions

- Follow RuboCop (`rubocop` + `rubocop-rails`). Run `bundle exec rubocop` before committing.
- Model concerns follow the naming pattern `Api::ModelName` and `RailsAdmin::ModelName` — see
  `docs/GUIDE.md` §1/§5 in the thecore repo for when a concern is needed at all (the default,
  concern-less case is correct for most models).
- To extend an ATOM's or the main app's endpoint classes at boot (e.g. add a custom action to
  `Endpoints::SomeModel`), use `class_eval` inside a `Rails.application.config.after_initialize`
  block in a dedicated initializer under `config/initializers/`. Do **not** use `include` with a
  concern module — `model_driven_api`'s Swagger discovery uses `instance_methods(false)`, which
  excludes methods from included modules.

- Use `Arel.sql(...)` when passing raw SQL to ActiveRecord query methods.
- Read a `ThecoreSettings` value where you use it, with
  `ThecoreSettings::Setting.find_by(ns: ..., key: ...)&.raw`, plus a fallback for a blank value. The
  `Settings.ns(...)` DSL memoizes a namespace for the life of the process, so a running Puma or
  Sidekiq worker keeps the old value after an admin edits it in RailsAdmin.
- **No background job is ever retried.** `thecore_backend_commons` sets Sidekiq's default to
  `retry: false` app-wide (mailer jobs included) and registers a death handler that records each
  failed job (class, queue, jid, error, never its arguments) in the Rails log. A failure is fixed
  and the job run again, or left to the next scheduled run. To record failures somewhere else too,
  add your own handler to `config.death_handlers` next to the default. Retries of a job that keeps
  failing (a mail with a large PDF refused by the SMTP server) fill Redis until the host runs out of
  memory.
- `perform_later`/`deliver_later` arguments must be ActiveJob-serializable: records (passed by
  GlobalID) or JSON-safe primitives. In production they round-trip through JSON to reach Redis, so
  binary data (PDF bytes, images) is passed `Base64.strict_encode64`-encoded and decoded in the job
  or mailer.
- **No secret in `vendor/deploytargets/`.** That folder is committed, so a `SECRET_KEY_BASE` (or an
  admin password) in a target's `.env` lets anyone who reads the repository forge an admin session.
  `SECRET_KEY_BASE` lives only on the Docker host, in
  `/root/persistence/${COMPOSE_PROJECT_NAME}/secrets.env`, kept by `thecore_devcontainer`'s deploy
  (its ADR 0004); rotate it through `SECRET_KEY_BASE_ROTATION` in the target's `.env`.

<!-- TODO: any app-specific conventions (background job queue naming, custom
     Rubocop cops, etc). -->

## Common commands

```bash
# Start server
bundle exec rails server

# Run migrations
bundle exec rails db:migrate

# Run tests
bundle exec rails test

# RuboCop
bundle exec rubocop

# Thecore-aware generators (see docs/GUIDE.md §7, "Command reference", in the thecore repo)
rails generate model NAME [fields...]
rails generate migration NAME [fields...]
rails generate thecore:root_action NAME
rails generate thecore:member_action NAME
rails generate thecore:collection_action NAME
rails generate thecore:atom NAME          # a new ATOM under vendor/submodules/ (see "Changing an ATOM")
rails thecore:check_practices -- --json
```

<!-- TODO: any app-specific commands (background job worker, one-off data
     import/export or integration scripts, etc). -->

## External integration

<!-- TODO: describe this app's own external integrations, if any (a third-
     party API, an external database, a customer-specific data source).
     Nothing universal to say here — most Thecore apps have none at all. -->

## Agent skills

### Issue tracker

Tasks, issues, bugs, tickets and specs for this repository live **only** in the issue tracker of
its git host: GitHub Issues for a `github.com` remote (`gh`), GitLab Issues for a GitLab one
(`glab`), picked from `git remote get-url origin`. See `docs/agents/issue-tracker.md`.

**Mandatory rule.** Whenever a skill or development work creates, reads, updates, comments on,
assigns, blocks or closes a task, issue, bug, ticket or spec (for example /to-tickets, /to-spec,
/triage, /wayfinder, /implement, /diagnosing-bugs, /code-review, closing a piece of work, a bug
found during a session), do it in that tracker following `docs/agents/issue-tracker.md`. `#123`
means an issue number of this repository. If the CLI doesn't work, stop and say so instead of
falling back to `.scratch/` or local Markdown files.

### Triage labels

The five canonical triage roles map to labels with the same name (`needs-triage`, `needs-info`,
`ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root, created lazily when the first
term or decision is resolved. See `docs/agents/domain.md`.
