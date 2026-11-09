# CLAUDE.md — <!-- TODO: ATOM name -->

<!--
  TODO: One or two sentences describing what this ATOM (Rails engine) does and
  what domain it owns. See docs/GUIDE.md §1 ("Philosophy")/§4 ("ATOMs") in the
  thecore repo for the conventions this file assumes — don't restate them
  here, link to them.
-->

## Gem overview

<!-- TODO: what this ATOM is for, who consumes it, and any gems it depends on
     beyond the Thecore ecosystem base (model_driven_api, thecore_ui_rails_admin,
     etc. — see this gem's own gemspec for the authoritative dependency list). -->

## Public API / concerns provided

<!-- TODO: the models, Api::/RailsAdmin:: concerns, custom REST endpoints, and
     any other public surface this ATOM exposes to a consuming host app. See
     docs/GUIDE.md §5 in the thecore repo for the concern-naming conventions
     this file assumes — don't restate them here, link to them. -->

## Models

<!-- TODO: this ATOM's own domain models and how they relate to each other,
     and to any models it expects the host app or other ATOMs to provide.
     Nothing universal to say here — every ATOM's domain is different. -->

## Claude Code skills

Matt Pocock's skill set is installed as the `mattpocock-skills` Claude Code plugin, on each
developer's own **host** machine (outside the devcontainer):

```bash
claude plugins install mattpocock-skills
```

(official Claude Code marketplace — nothing to add first; updates arrive automatically. See
https://github.com/mattpocock/skills.) This applies whether you're working on this ATOM inside a
host app's `vendor/submodules/` (the devcontainer there bind-mounts the host's `~/.claude`
directory wholesale) or checked out on its own as a standalone repository with its own
devcontainer — the plugin mechanism is host-machine-level, not tied to any one working directory.

`ask-matt`'s own SKILL.md (inside the plugin) is the authoritative map of how the skills connect
(main flow, on-ramps, standalone).

<!-- TODO: once this ATOM has its own issue tracker configured (run
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

- **Update this file** whenever you add or modify a model, concern, endpoint, or other public
  surface this ATOM exposes. Keep descriptions accurate — stale docs cause incorrect future edits.
- **Update README.md** whenever this gem's dependencies, setup steps, or consumption instructions
  change.
- **Add or update tests** for every change. New functionality must have test coverage; modified
  behaviour must have its existing tests updated to match.

## Code conventions

- Follow RuboCop (`rubocop` + `rubocop-rails`). Run `bundle exec rubocop` before committing.
- Model concerns follow the naming pattern `Api::ModelName` and `RailsAdmin::ModelName` — see
  `docs/GUIDE.md` §1/§5 in the thecore repo for when a concern is needed at all (the default,
  concern-less case is correct for most models).
- To add a custom, non-CRUD REST action to one of this ATOM's own `Endpoints::` classes, use
  `class_eval` inside a `Rails.application.config.after_initialize` block in a dedicated
  initializer under `config/initializers/`. Do **not** use `include` with a concern module —
  `model_driven_api`'s Swagger discovery uses `instance_methods(false)`, which excludes methods
  from included modules.

<!-- TODO: any ATOM-specific conventions. -->

## Common commands

Run from this ATOM's own gem root (its tests live at the top level, not inside `test/dummy/` —
`test/dummy/` is only the runtime fixture app the tests boot against):

```bash
bundle install

# Create this ATOM's own test database (once, or after the db volume is recreated)
bin/rails db:create

# Run this ATOM's own test suite
bin/rails test

# RuboCop
bundle exec rubocop
```

The dummy app runs on PostgreSQL. Its `config/boot.rb` keeps only the server and credentials of a
`DATABASE_URL` (the devcontainer sets one, pointing at the host app's development database) and
always uses `<this-atom-name>_<RAILS_ENV>`, so running these tests never touches development data.

If you're working on this ATOM from inside a host app (i.e. this file lives under that app's
`vendor/submodules/<this-atom-name>/`), the host app's own Thecore-aware generators can target
this ATOM directly — see that app's `CLAUDE.md` and `docs/GUIDE.md` §7 ("Command reference") in
the thecore repo, for example `rails generate model NAME --atom=<this-atom-name>` run from the
host app's root, or the same command run from inside this ATOM's own directory with no `--atom`
flag needed. These aren't available when this ATOM is checked out standalone, outside any host
app — there's no Rails process to run them against in that case.

<!-- TODO: any ATOM-specific commands (a rake task this ATOM adds, a seed
     script, etc). -->

## Publishing

This ATOM is a gem. A host app consumes it from a gem server, with this repository cloned in the
host's `vendor/submodules/<name>` only to edit it. The repository's branch is `release/3`: it is
the only branch that publishes, so work on another branch and merge into `release/3` to release.

1. Edit and test here.
2. Bump `lib/<name>/version.rb` and push to `release/3`. The CI publishes the new version and tags
   it; a push that doesn't change the version publishes nothing.
3. Wait until the new version is on the gem server.
4. In the host app: `bundle update <name> --conservative`, then commit the new `Gemfile.lock`
   together with the moved submodule pointer.

Where it publishes depends on where the repository lives, and the gemspec's `allowed_push_host`
must name that same server (`gem push` refuses any other):

- **RubyGems.org** (the Thecore base gems, hosted on GitHub): `.github/workflows/gempush.yml`
  runs on pushes to `release/3`, tags the version and pushes it with the `RUBYGEMS_AUTH_TOKEN`
  repository secret. `allowed_push_host` is `https://rubygems.org`.
- **A private gem server** (gems hosted on a GitLab instance): `.gitlab-ci.yml`'s `build_gem` runs
  the image's `gem-compile.sh` only when `lib/*/version.rb` changes, and never on a tag. It pushes
  to `GITLAB_GEM_REPO_TARGET` with `GEM_HOST_API_KEY` (a CI/CD variable holding the server's
  credentials), or to RubyGems.org when `GITLAB_GEM_REPO_TARGET` is unset. `allowed_push_host`
  is that server's URL, and the host app declares the gem inside its `source "https://<server>/"
  do ... end` block.

`rails generate thecore:atom NAME --gem-host=<server host>` writes both for a private server; with
no `--gem-host` it targets RubyGems.org. To move an existing ATOM, change `allowed_push_host` and
`GITLAB_GEM_REPO_TARGET` together.

## Security scanning

Scans report; they never block a release.

- **GitLab** (`.gitlab-ci.yml`): GitLab's **SAST** (Semgrep) and **Secret Detection** templates
  run on every push, with `needs: []`, so they start with the pipeline. On GitLab CE they only
  write `gl-sast-report.json`/`gl-secret-detection-report.json` and stay green whatever they find,
  so `security-summary` (`allow_failure`) runs `script/security_summary.rb` on both reports: it
  lists the findings in its log and turns orange when there are any, or when a report is missing
  (`test/script/security_summary_test.rb`, which `bin/rails test` runs with the rest). The reports
  reach it as job artifacts, so artifacts must be enabled on the GitLab instance.
- **GitHub**: code scanning (CodeQL default setup), Dependabot alerts and secret scanning with push
  protection are enabled in the repository's settings, not in a workflow.
- CVEs in this gem's dependencies are checked by the host app's `bundler-audit`: this gem commits
  no `Gemfile.lock`, and the host's resolves every ATOM it uses.

When a finding needs work, open an issue in this repository's tracker.

## External integration

<!-- TODO: describe any external integration this ATOM owns (a third-party
     API, an external data source). Nothing universal to say here — most
     ATOMs have none at all. -->
