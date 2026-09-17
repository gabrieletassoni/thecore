# App application template (Phase 3) scoped to `rails new -m` only; devcontainer/CI/CLAUDE.md assets sourced from thecore's own `samples/`, not duplicated in thecore_generators

ADR 0004 deferred all of Phase 3 as a block — the `thecore:atom` generator (porting `createATOM.js`), the `rails new -m` App application template (porting `createApp.js`), and a Collection Action generator — with "none of Phase 3's scope should be started before Phase 2 lands." Phase 2 has since shipped in full (tickets #11-15/#36-38, `thecore_generators` 3.6.0 released to RubyGems). This ADR scopes only the App application template out of that deferred block. The `thecore:atom` generator and the Collection Action generator remain deferred to a future session — tracked here, under Delivery tracking, so they aren't lost.

The App template's reference for "what a good Thecore host app looks like" is the `mytrack` backend (the workspace this decision was made in) — but only its *generic* shape, not its Bancolini-specific customization. The boundary rule: anything not portable to a different customer stays out. Excluded: the devcontainer's VPN build (strongSwan/IPSec), the `gems.bancolini.com` private Gemfile source block, the `mytask`/`thecore-spot-overrides` customer submodules, and CLAUDE.md's domain-model/external-integration sections. Carried over as generic: the devcontainer's Claude Code plugin-mount mechanism, `.rubocop.yml`, the base `thecore_*` ecosystem gem list, and CLAUDE.md's skill-workflow/code-conventions sections.

`vendor/submodules/` and `vendor/external/` are **not** template content at all. The template creates them empty (a `.keep` file each) and documents them as developer-convenience directories for cloning auxiliary repos during local development — not as a menu of gems or submodules to pre-wire into a new app.

**Where the generic assets live.** `thecore` (this docs repo) already maintains `samples/devcontainer/` as the canonical reference devcontainer, linked from `docs/SETUP_VSCODE*.md` — but it predates the `mattpocock-skills` plugin mechanism (host-home symlink, `check-plugins.sh`) and the gh/glab CLI mount pattern the `mytrack` backend now has. Rather than have the App template carry a second copy of these files — a second source of truth that drifts the moment either copy is edited — this ADR's delivery updates `thecore/samples/devcontainer/` to the current best-practice state first, and the App template's `rails new -m` script fetches/copies directly from there (plus new sibling sample files this work adds for `CLAUDE.md` and `.gitlab-ci.yml`) via raw GitHub URLs. The template script itself (`app_template.rb`) still lives in `thecore_generators`'s own repo, invoked as `rails new myapp -m https://raw.githubusercontent.com/gabrieletassoni/thecore_generators/release/3/lib/templates/app_template.rb` — only the *assets* it materializes are sourced from `thecore`.

A newly generated devcontainer's `gh`/`glab` CLI config mounts are present in `devcontainer.json` but **commented out by default**, with a one-line comment explaining how to enable each if the developer already has that tool configured on their host OS — the same discoverable-but-optional shape as the Gemfile's commented block of the rest of the `thecore_*` ecosystem gems beyond the always-active core set (devise, cancancan, rails_admin, sassc-rails, `model_driven_api`, `thecore_ui_rails_admin`).

**CI/CD.** The template generates only a genericized `.gitlab-ci.yml` (no Bancolini-specific script paths or private infra references) — not a GitHub Actions equivalent. This matches the Thecore convention already documented in `thecore`'s own CLAUDE.md ("GitLab CI: `docker-deploy.sh` for Docker image builds" for Thecore *applications*; GitHub Actions is reserved for *gem* publishing). The deploy stage is kept, not stripped to a build/test-only pipeline, because the devcontainer-provided deploy scripts already read their target configuration from `vendor/deploytargets/` and no-op safely when that's absent — exactly the state a freshly generated app is in.

**Sequencing.** `rails new -m` needs a working Ruby/Rails, which today only exists inside a devcontainer already created by the existing, unrelated "Setup Devcontainer" VS Code command (`setupDevContainer.js`) — a bootstrap step this ADR leaves untouched. The App template runs *inside* that bootstrap devcontainer and overwrites `.devcontainer/*` (along with CI and CLAUDE.md) with the full, enriched version fetched from `thecore/samples/`; a container rebuild afterward picks up the richer config. No new bootstrap mechanism is introduced.

**CLAUDE.md.** The template generates a skeleton containing only universal sections (the `mattpocock-skills` plugin mechanism, the required skill sequence, generic Ruby/Rails code conventions, a common-commands list with placeholders) and leaves project-specific sections (repository structure, key domain models, external integrations) as clearly marked TODO placeholders — there's no domain yet to describe in a freshly generated app.

**Interaction mode.** The template only supports interactive prompts (`ask`/`yes?`) in this first version — no unattended/headless invocation path.

**Documentation.** `thecore`'s `docs/GUIDE.md` and `docs/WALKTHROUGH.md` are the canonical, official home for all of this, including finishing the one gap Phase 2 left behind: `check_practices` has no row in GUIDE.md §7's command-reference tables and no worked `--fix` example in WALKTHROUGH.md. Phase 1 (Model/Migration generators) is already fully and correctly documented there and needs no further work.

## Status
accepted

## Consequences
- `thecore/samples/devcontainer/` stops being a static, rarely-touched reference and becomes a live dependency the App template fetches at `rails new -m` time — a breaking change to its file layout or content is now a breaking change for the template, not a free edit.
- The App template intentionally produces a *blank* host app with no pre-wired customer submodules or vendor gems beyond the generic core — a new customer project still needs its own follow-up session to add its actual `vendor/submodules/` entries.
- Neither the VS Code "Create App" command (`createApp.js`) nor "Setup Devcontainer" (`setupDevContainer.js`) is touched by this ADR. `createApp.js` keeps its current, fully JS-side implementation until a later, separate ticket delegates it to this Ruby template (mirroring the #36-38 delegation pattern).

## Delivery tracking

This ADR scopes only the App application template piece of ADR 0004's deferred Phase 3. Tickets to be filed under `thecore`/`thecore_generators` per `/to-tickets` are expected to include (not yet filed as of this ADR):
- `thecore`: update `samples/devcontainer/` to the current best-practice state (mattpocock-skills mounts, host-home symlink, `check-plugins.sh`, commented-out gh/glab mounts); add sibling generic `CLAUDE.md`/`.gitlab-ci.yml` samples; fix the `check_practices` documentation gap in `GUIDE.md`/`WALKTHROUGH.md`; document the App template itself.
- `thecore_generators`: `lib/templates/app_template.rb` (the `rails new -m` script), fetching its assets from `thecore`'s samples.

**Still deferred beyond this ADR** (tracked, not forgotten): the `thecore:atom` generator (porting `createATOM.js`) and the Collection Action generator, both explicitly left for a future session, same as ADR 0004 left them.

**Explicitly out of scope, tracked as future-improvement issues rather than silently dropped:**
- A GitHub Actions pipeline equivalent to the App template's generic GitLab CI pipeline.
- An unattended/non-interactive invocation mode for the App template (today interactive-only).

## Considered Options
- Duplicate the devcontainer/CI/CLAUDE.md asset files inside `thecore_generators` itself instead of fetching from `thecore` — rejected: creates two copies of the same reference that inevitably drift, defeating the "canonical documentation lives in `thecore`" principle this whole initiative already follows for prose docs.
- Prompt interactively for GitHub Actions vs GitLab CI — rejected: no generic, tested GitHub Actions equivalent exists yet for Thecore *applications* (only for gem publishing), so offering the choice today would generate an untested, unsupported pipeline; tracked as a future issue instead.
- Copy the `mytrack` backend's `.gitlab-ci.yml`/devcontainer/CLAUDE.md content verbatim as the template's baseline — rejected: large parts (VPN build, private gem source, customer submodules, MS SQL/Gamma integration docs) are Bancolini-specific and not portable to a different customer's app.
