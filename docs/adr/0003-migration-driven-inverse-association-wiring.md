# Migration-driven inverse-association wiring, written to a per-target-model concern

Rails' own `references` migration generator only ever wires the owning side (`belongs_to`) — the inverse (`has_many`/`has_one`) has always been manual. `thecore_generators`' migration generator now detects `references` columns and, when run interactively, prompts for the inverse association's cardinality (`has_many` default, `has_one`, or skip); non-interactive/extension-invoked runs default to `has_many`. The association is written into a canonical per-target-model concern (`config/initializers/concern_<target_model>.rb` + a `TargetModel.send(:include, ...)` line in `after_initialize.rb`, per the pattern `GUIDE.md §4.5` already establishes for cross-ATOM model extension), idempotently — re-running the generator against the same target model appends into the existing file rather than creating a new one, and skips associations already present. The concern lives in whichever app/ATOM the generator was invoked from (the one gaining the new reference and its dependency), not the target model's own app/ATOM. When the target model lives in a different ATOM/app than the invoking one, the generator still writes the concern automatically but only logs the required gemspec/Gemfile dependency addition for a human to apply, rather than editing dependency manifests itself.

## Status
accepted

## Consequences
Every model gaining an inbound reference from elsewhere accumulates one long-lived, generator-maintained concern file rather than scattering associations across many small ones — but that file's generated origin needs to be obvious to a reader, which is why this convention must be well documented in thecore's own docs (not left implicit), so accumulated associations are never mistaken for a hand-written concern with hidden intent. Cross-boundary references still require a manual dependency-manifest edit — deliberately, since adding a new gem dependency is architecturally significant enough to want a human's eyes.

## Considered Options
- Never auto-add the inverse association, only guarantee `belongs_to` — rejected: leaves the actual pain point (manually keeping both sides of an association in sync) completely unsolved.
- One file per migration instead of accumulating per target model — rejected: recreates the generated-file sprawl this whole effort exists to reduce.
- Fully automate cross-boundary dependency wiring too — rejected: a new gem dependency has real architectural consequences (per ADR 0002's ATOM-boundary reasoning) that deserve human confirmation, same as everywhere else this design defers to a human at a boundary crossing.
