# Default model behavior lives on ApplicationRecord, not in three always-generated concern files

Every "Add a Model" invocation generates `Api::`, `RailsAdmin::`, and `Endpoints::` concern files per model, even though auditing `mytask`'s real usage shows most carry no per-model content beyond boilerplate (`Endpoints::` is generated but never even `include`d into the model). This deliberately supersedes `GUIDE.md`/`WALKTHROUGH.md`'s stated "Fat model via concerns"/"High standardisation" philosophy: default behavior for the no-customization case now lives on `ApplicationRecord`, generically `include`d into every subclass at boot by whichever gem already owns that concern's runtime behavior (`model_driven_api` for `Api::`/`Endpoints::`, `thecore_ui_rails_admin` for `RailsAdmin::`'s mechanically-derivable parts like `navigation_label`/icon) — not centralized in one gem. Per-model concern files are generated/kept only for genuine customization, following the `after_initialize` + `class_eval`/`.send(:include, ...)` pattern already established for `Endpoints::*` custom actions.

## Status
accepted

## Consequences
The default-include mechanism must use an `ActiveSupport::Concern`-style `included do` block (not a plain `include`), so default methods land as *own* methods on each model class — `model_driven_api`'s `/info/schema`/`/info/dsl` introspection (`instance_methods(false)`) depends on this. Adoption is prospective for existing thecore apps; retroactive within the gems hosting the new defaults themselves. `GUIDE.md`/`WALKTHROUGH.md` will be updated to reflect the superseded philosophy.

## Considered Options
- Centralize all defaults in `thecore_backend_commons` — rejected: would make that gem reach into `model_driven_api`'s introspection contract from outside its own domain.
- Leave `RailsAdmin::` fully as generated files (no consolidation) — rejected: even though current `mytask` models never left it empty, simpler models across the ecosystem plausibly need only the derivable defaults.
