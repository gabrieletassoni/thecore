# thecore_generators: a dedicated gem hooking Rails' own generator commands, not a new command vocabulary

The VS Code extension currently owns 8 scaffolding operations (model, migration, app, ATOM, root/member/collection action, plus a check/auto-fix tool) entirely in JS, outside any Ruby/Rails tooling, undiscoverable outside VS Code and impossible to run in CI. This work moves that logic into a new gem, **`thecore_generators`**, branched/versioned alongside the other thecore gems (`release/3` for Rails 7, `release/4` for Rails 8 when it lands).

Wherever Rails already has a native command to override, we override it rather than invent a new one. Model and Migration generation hook via `config.app_generators.orm :thecore, migration: true, timestamps: true`, registered in the gem's Railtie — confirmed live in Rails 7.2 (this is the exact mechanism ActiveRecord's own Railtie and Mongoid both use). Plain `rails generate model`/`rails generate migration` then transparently pick up thecore's scaffolding (default-first concerns per ADR 0001, ATOM-vs-host-app placement, non-suppressed test generation) with **zero new vocabulary for developers**; `rails generate active_record:model` remains available as an escape hatch since Rails only hides the override from `--help`, never blocks direct invocation.

Context detection (host app vs. ATOM) reads the invoking terminal's `Dir.pwd` — mirroring the extension's already-proven `workspaceContext.js` gemspec-presence check under `vendor/submodules/` — with an explicit `--atom=NAME` override for scripted/CI invocations.

Not every operation fits the override trick. New app bootstrapping (`createApp`) becomes a **Rails application template** (`rails new myapp -m <thecore template>`) instead of a generator, since there's no existing Rails boot to hook into. ATOM creation and Root/Member/Collection Action scaffolding have no Rails-native command to override, so they become new `thecore:*`-namespaced generators. The extension's VS Code-only `checkPractices` diagnostics become a `rails thecore:check_practices` rake task, usable in CI.

Delivery is phased within the one gem: **Phase 1** — Model + Migration generators (including the reference→inverse-association wiring, see ADR 0003) and the `check_practices` rake task. **Phase 2** — the App application template and the ATOM/Action generators.

## Status
accepted

## Consequences
The extension's own commands become thin wrappers shelling out to these Rails-native tools (mirroring how `addModel.js` already shells out to `rails g model` today) rather than reimplementing generation logic in JS — it must adopt each phase as it lands rather than let its JS implementation drift out of sync. `app_generators.orm` is a single process-wide setting; if a thecore app ever adds another ORM-overriding gem, the two would conflict (last-write-wins by require order) — not a concern today, but worth remembering.

## Considered Options
- Keep app bootstrapping as a generator/rake task for consistency with everything else — rejected: application templates are Rails' actual native mechanism for "no app exists yet," more discoverable to developers who've never touched thecore.
- New command names for Model/Migration (e.g. `rails generate thecore:model`) — rejected: `config.app_generators.orm` lets plain `rails generate model`/`migration` "just work," strictly better for discoverability with no downside found.
