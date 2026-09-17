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
# Run this ATOM's own test suite
bundle exec rake test

# RuboCop
bundle exec rubocop
```

If you're working on this ATOM from inside a host app (i.e. this file lives under that app's
`vendor/submodules/<this-atom-name>/`), the host app's own Thecore-aware generators can target
this ATOM directly — see that app's `CLAUDE.md` and `docs/GUIDE.md` §7 ("Command reference") in
the thecore repo, for example `rails generate model NAME --atom=<this-atom-name>` run from the
host app's root, or the same command run from inside this ATOM's own directory with no `--atom`
flag needed. These aren't available when this ATOM is checked out standalone, outside any host
app — there's no Rails process to run them against in that case.

<!-- TODO: any ATOM-specific commands (a rake task this ATOM adds, a seed
     script, etc). -->

## External integration

<!-- TODO: describe any external integration this ATOM owns (a third-party
     API, an external data source). Nothing universal to say here — most
     ATOMs have none at all. -->
