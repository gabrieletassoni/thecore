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

`ask-matt`'s own SKILL.md (inside the plugin) is the authoritative map of how the skills connect
(main flow, on-ramps, standalone).

<!-- TODO: once this app has its own issue tracker configured (run
     /setup-matt-pocock-skills), list which skills are user-invoked-only
     (`disable-model-invocation: true`) vs model-invocable here — it depends
     on tracker choice, which is project-specific. -->

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
rails thecore:check_practices -- --json
```

<!-- TODO: any app-specific commands (background job worker, one-off data
     import/export or integration scripts, etc). -->

## External integration

<!-- TODO: describe this app's own external integrations, if any (a third-
     party API, an external database, a customer-specific data source).
     Nothing universal to say here — most Thecore apps have none at all. -->
