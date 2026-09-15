# thecore framework

The scaffolding/convention framework for Rails apps built on thecore: a host app plus modular Rails engines (**ATOMs**, see `docs/GUIDE.md §4.1`) tied together by shared conventions, generators, and gem-level defaults.

## Language

**Default module**:
A gem-owned module carrying an `ApplicationRecord.subclass`'s default behavior (e.g. default `Api::` serialization shape, default `RailsAdmin::` navigation config), generically `include`d into every subclass at boot rather than requiring a per-model generated concern file. Only models needing genuine customization get a hand-maintained concern on top. See ADR 0001.
_Avoid_: base concern, shared concern, ApplicationRecord mixin

**Generator hook**:
The `config.app_generators.orm :thecore` mechanism a gem's Railtie registers so that Rails' own `rails generate model`/`rails generate migration` commands transparently run thecore's scaffolding — no new command name for developers to learn. Distinct from a *new* `thecore:*`-namespaced generator (used only where Rails has no native command to override, e.g. ATOM or Action scaffolding). See ADR 0002.
_Avoid_: generator override, ORM hook (ambiguous with Rails' own `--orm` flag)

**Generator context**:
Whether a generator invocation is scoped to the host app or to a specific ATOM, detected from the invoking terminal's working directory (mirroring the code extension's `workspaceContext.js` gemspec-presence check under `vendor/submodules/`), with an explicit `--atom=NAME` override for scripted/CI invocations. Determines where generated files (models, migrations, concerns) land.
_Avoid_: workspace context (that's the extension's own internal term), invocation mode

**Inverse-association wiring**:
The migration generator's detection of a `references` column and automatic authoring of the inverse `has_many`/`has_one` on the target model, written into that model's per-target-model concern rather than editing the target model file directly. Rails' own migration generator only ever wires the owning (`belongs_to`) side; this fills the other half. See ADR 0003.
_Avoid_: reverse association, back-reference, auto-association

**thecore_generators**:
The dedicated gem hosting all of thecore's Rails-native scaffolding: the generator hook for Model/Migration, the inverse-association wiring, the `thecore:check_practices` rake task (JSON output, `--fix` flag — see ADR 0004), and the Root/Member Action generators. The ATOM generator, the application-creation template (invoked via `rails new -m`, not a generator), and Collection Action support remain a later, unscoped phase. See ADR 0002 and ADR 0004.
_Avoid_: thecore generator, scaffolding gem

**Violation** (as checked by `thecore:check_practices`):
A single non-conformance the rake task detects and reports as one structured entry (`file`, `line`, `message`, `severity`, `fixable`) — the Ruby-side counterpart to `thecore_code_extension`'s own `Violation` (its own CONTEXT.md), which now renders these as VS Code diagnostics instead of detecting them itself. A model with no `Api::`/`RailsAdmin::` concern file is never a Violation on its own (see ADR 0001's default module) — only an `include` pointing at a missing concern, or a concern file missing its required marker, is. See ADR 0004.
_Avoid_: audit finding, practices error, lint issue
