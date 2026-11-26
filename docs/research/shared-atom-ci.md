# Sharing CI definitions and service versions across ATOM repos

Research for wayfinder ticket #25 (map #23), 2026-11-26. Facts only; the decision belongs to #27.

**Question.** How can ~14 ATOM repos, split between public GitHub (`gabrieletassoni/*`, GitHub Actions) and private Bancolini GitLab (`devops.bancolini.com`, GitLab CI), share CI job definitions and service versions (postgres, redis, later whatever Solid needs), and what are the limits?

## Current state (local evidence)

- `postgres:15-bookworm` is written literally in: 7 `gempush.yml` (model_driven_api, thecore_auth_commons, thecore_backend_commons, thecore_generators, thecore_settings, thecore_ui_commons, thecore_ui_rails_admin; thecore_background_jobs, thecore_download_documents and thecore_tcp_debug have older 24–56 line workflows with no service), 2 SPOT/mytask `.gitlab-ci.yml` (mytask, thecore-spot-overrides; spot-items-common/importer have none), the `thecore:atom` generator twice (`atom_generator.rb` lines ~132 for GitHub, ~737 for GitLab), the host's `.gitlab-ci.yml` (line ~119, commented "The devcontainer's versions") and `thecore_devcontainer/docker/docker-compose.yml` (`postgres:15-bookworm`, `redis:7-bookworm`). `redis:7-bookworm` is in CI only in thecore_backend_commons.
- The GitHub and GitLab files are already structurally parallel (test job with PG* env → gated publish job), so a shared definition has to be expressed twice, once per platform: **no mechanism shares a single job definition across GitHub Actions and GitLab CI**; only data (versions) can be shared across both.
- A shared vehicle already exists on GitLab: every SPOT job runs in `gabrieletassoni/vscode-devcontainers-thecore:3`, and `build_gem` calls `/usr/bin/gem-compile.sh` baked into that image (`thecore_devcontainer/scripts/gem-compile.sh`). Script logic can be shared that way; **service images cannot**, because `services:` is resolved before the job's image runs.
- Bancolini GitLab is **GitLab CE 19.5.6** (`/api/v4/version`: `"version":"19.5.6","enterprise":false`). Every GitLab feature below is available on that version and tier unless noted.

## Mechanisms on GitHub Actions

| Fact | Source |
| --- | --- |
| A reusable workflow (`on: workflow_call`) is called as a whole **job**: `jobs.x.uses: owner/repo/.github/workflows/file.yml@ref`. It must sit directly in `.github/workflows` (no subdirectories). | [GH-reuse] |
| `@ref` may be a SHA, a tag or a branch; a tag wins over a branch of the same name; "Using the commit SHA is the safest option for stability and security." `uses:` accepts no expressions, so the ref can't be computed. | [GH-reuse] |
| Callable when "the called workflow is stored in a public repository" (plus, for organisations, the org allows public reusable workflows). All `gabrieletassoni/*` ATOMs are public repos of a personal account, so any of them can call a workflow in `gabrieletassoni/thecore` (or another public repo). | [GH-ref] |
| Limits: 10 levels of nesting, "a maximum of 50 unique reusable workflows from a single workflow file", no loops. | [GH-ref] |
| Caller workflow-level `env` is **not** propagated to the called workflow; values travel via `inputs` / `secrets`. `secrets: inherit` is documented for same org/enterprise; passing `RUBYGEMS_AUTH_TOKEN` explicitly by name always works. Permissions can only be kept or reduced down the chain (the publish job needs `contents: write`, so the caller must grant it). | [GH-ref], [GH-reuse] |
| `jobs.<id>.services` and `jobs.<id>.container.image` accept the contexts `github, needs, strategy, matrix, vars, inputs`. So a service image **can** come from a reusable-workflow input (`image: ${{ inputs.postgres_image }}`), from a configuration variable (`vars`), or from a previous job's output (`needs.<job>.outputs.*`). | [GH-ctx] |
| Composite actions (`runs.using: composite`) contain only steps: they can share step sequences (setup Ruby, db:create, run tests, publish) but cannot declare `services:`. | [GH-composite] |
| `vars` exist at repository, environment and organisation level. A personal account has no org level, so a cross-repo `vars` value would have to be set in each of the ~10 repos. | [GH-vars] |

## Mechanisms on GitLab CI

| Fact | Source |
| --- | --- |
| `include:project` + `file` + `ref` (branch, tag or SHA; full 40-char SHA "most stable"; `refs/tags/..` disambiguates). Recommended over remote: fetches "from other projects in the GitLab instance without making external HTTP(S) requests". Private source → pipeline user needs Reporter. | [GL-yaml], [GL-inc] |
| `include:remote`: "a public URL that responds to an HTTP/HTTPS GET", **no authentication**, `.yml`/`.yaml` only; nested includes in it run "as a public user" with no variables. Failures are "connectivity issues" / rate limits at pipeline creation → the pipeline is not created. | [GL-yaml], [GL-inc] |
| `include:integrity` (17.9): Base64 SHA256 of the remote content; mismatch fails the pipeline. Pins content (equivalent to a SHA ref), so every content change means editing every caller. | [GL-yaml] |
| `include:cache` (experiment 18.9, GA 19.0): caches a remote include, `true` = 1 h, max 1 day; stale content is served until TTL expiry. | [GL-yaml] |
| CI/CD **components** (GA 17.0, Free tier): `include:component: $CI_SERVER_FQDN/group/project/name@version`, typed `spec:inputs`, partial semver (`@1`, `@1.2`) and `@~latest` work only for components published in the **CI/CD Catalog** (needs a `release`-keyword job and semver tags). Components are **instance-local**: GitLab.com components must be mirrored into a self-managed instance; GitHub is not a source. `spec:include` is not allowed in a component. | [GL-comp] |
| Max 150 nested included files per pipeline. Includes are evaluated before jobs; include paths may use only project/group/instance, predefined `CI_PROJECT_*`, trigger/schedule/manual variables. | [GL-inc] |
| An included file's `variables:` merge into the pipeline (main file wins on conflict), and `services:name` / `image` are expanded **by the runner** with CI/CD variables, so `services: [{name: $POSTGRES_IMAGE}]` fed from an included `variables:` block works. (Expanding service names from a dotenv artifact of a previous job is not documented: verify before relying on it.) | [GL-inc], [GL-where] |
| Pull mirroring (e.g. GitHub → GitLab) is **Premium/Ultimate only**; Bancolini runs CE, so a GitHub repo can only reach GitLab by being pushed there (e.g. a GitHub Actions job `git push` to a GitLab project with a deploy token). | [GL-mirror] |

### Can Bancolini GitLab include a file from raw.githubusercontent.com?

Syntactically yes: `include: - remote: https://raw.githubusercontent.com/gabrieletassoni/thecore/<sha-or-tag>/ci/versions.yml` meets every documented requirement (public, GET, `.yml`). Not verified for this instance; what needs checking:

1. **Egress**: can the GitLab Rails/Sidekiq nodes at devops.bancolini.com resolve and reach `raw.githubusercontent.com:443` (corporate firewall/proxy)? Test: a throwaway project with a one-line remote include, or `curl` from the GitLab host.
2. **Outbound request filtering**: Admin → Settings → Network → Outbound requests, "Block all requests, except … the allowlist" (Free tier) ([GL-outbound]). The docs do not say whether `include:remote` honours it; if it is on, add the GitHub raw host to the allowlist and test.
3. **Availability coupling**: every pipeline creation (including scheduled nightlies) would depend on GitHub being up and on its unauthenticated raw-content rate limits; `include:cache` (≤ 1 day) softens that, at the price of serving stale content for up to the TTL.
4. **Security**: whoever can push to the referenced GitHub ref can change jobs that run with Bancolini's `BANCOLINI_WRITABLE_GEMS_CREDENTIALS` / `GITLAB_PAT` variables in scope. Mitigations: reference a commit SHA in the URL or set `include:integrity`; include only a data file (variables), never job definitions, from outside the instance.

## Bumping versions automatically

| Tool | What it covers | Source |
| --- | --- | --- |
| **Dependabot** `github-actions` | Action refs (`owner/repo@v4`) and remote reusable workflow refs; **not** Docker images in `services:`/`container:` (not mentioned; `docker://` refs explicitly unsupported). `docker`/`docker-compose` ecosystems update Dockerfiles / compose files (e.g. thecore_devcontainer's `docker-compose.yml`). GitHub-hosted repos only: no GitLab support. | [DB-eco] |
| **Renovate** `github-actions` | Action refs, reusable workflow refs (`workflow` depType), and Docker images in `container:` and `services:` (`service` depType). An image passed as a reusable-workflow `with:` input is **not** a recognised field (the `uses-with` depType is limited to known setup actions): it needs a `customManagers` regex. | [RN-gha] |
| **Renovate** `gitlabci` / `gitlabci-include` | `image`, `services` images, component references; `include` project refs via the `gitlab-tags` datasource. Runs on self-managed GitLab only as a **self-hosted** Renovate (e.g. a scheduled pipeline with a bot token); the hosted Mend app covers GitHub. | [RN-glci], [RN-glinc] |
| **Renovate** `customManagers` (regex) | Any file, any format: the single way to bump tags held in a plain versions file (`POSTGRES_IMAGE=postgres:15-bookworm`) or in a reusable-workflow input, using the `docker` datasource. | [RN-regex] |

## Options compared

| | (a) Central reusable workflow (GitHub) + `include:project`/component (GitLab) | (b) Versions file read at CI time | (c) Per-file copies + alignment check | (d) Hybrid: central versions data, platform-native shared jobs |
| --- | --- | --- | --- | --- |
| What is shared | Whole test/publish jobs **and** versions | Versions only; jobs stay copied | Nothing at runtime; a check fails on drift | Versions in one file; jobs shared per platform (reusable workflow on GitHub, component/`include:project` on GitLab) |
| GitHub mechanics | `jobs.test.uses: gabrieletassoni/thecore/.github/workflows/atom-test.yml@<ref>` with inputs (`redis: true`); services from `inputs` | A first job reads the file (checkout of the central repo or `curl` raw) and exposes outputs; the test job's `services.*.image: ${{ needs.versions.outputs.postgres }}` | Literal images; Renovate `service` depType can bump each copy | Reusable workflow holds the image tags itself, or its versions job reads the file |
| GitLab mechanics | Needs the shared YAML **inside the GitLab instance** (components/`include:project` are instance-local), i.e. a second copy of the definition, or `include:remote` from GitHub (egress + trust unverified) | `include:project` (a Bancolini project) or `include:remote` (GitHub raw) of a YAML with `variables:`; `services: - name: $POSTGRES_IMAGE` | Literal images; self-hosted Renovate or a check job | Bancolini component/`include:project` for jobs; the versions YAML either mirrored by push from GitHub or kept as a Bancolini-side copy checked against GitHub's |
| Propagation of a change | Branch ref: next run everywhere (no review per repo, can break all at once). Tag/SHA ref: one bump PR per ATOM (Renovate/Dependabot can open them) | Same choice: branch = immediate, SHA/tag = per-repo bump | One commit per file (~15 files + generator); a check catches the forgotten one | As (a)/(b) |
| Fresh-dependency nightly (#23 settles Gemfile.lock untracked) | Unaffected | Unaffected | Unaffected | Unaffected |
| Fits "dual CI must be equivalent" (ADR 0006) | Equivalence moves into two central definitions (one per platform) instead of 14 repos | Versions equal by construction; job equivalence still per repo | Equivalence only as good as the check | Both versions and job shape centralised per platform |
| Generator impact | `thecore:atom` writes a short caller file per platform | Writes the reader job + variable-based services | Writes literals (as today) | Short callers |
| Main limits | Cross-platform single definition impossible; GitLab side cannot consume GitHub-hosted components; reusable workflow called as a job only (no per-step customisation, no `env` propagation) | Extra job/HTTP fetch per pipeline; GitHub raw from GitLab unverified; Renovate needs a regex manager for the file | Drift is detected, not prevented; many PRs per bump | Two central definitions to keep equivalent (but 2, not 14) |

Other mechanisms checked and why they fall short:
- **GitLab pull mirror of `thecore` onto Bancolini**: would make `include:project`/components local, but pull mirroring is Premium; CE needs a GitHub-side job pushing to GitLab (needs a Bancolini token stored as a GitHub secret).
- **Baking versions into the devcontainer image** (like `gem-compile.sh`): fine for scripts, useless for `services:`, which are resolved before the image runs.
- **GitHub `vars`**: no org level on a personal account, so no single place.

## What this means for the decision in #27 (facts, not decisions)

- Job definitions can be centralised **per platform**, never once for both: GitHub via a reusable workflow in a public repo, GitLab via `include:project` or a Catalog component that must live **on devops.bancolini.com**. Versions (data) are the only thing a single file can serve to both.
- GitHub can take service images from reusable-workflow `inputs`, `vars` or a previous job's outputs; GitLab from CI/CD variables merged from an include. Both platforms therefore support "versions in one place" technically.
- Reading anything from GitHub at GitLab pipeline creation depends on unverified egress from devops.bancolini.com to `raw.githubusercontent.com`, on GitHub availability for every pipeline (nightlies included), and on trusting the GitHub ref with jobs that see Bancolini's gem-server credentials. Pinning (SHA/`include:integrity`) removes the trust issue but brings back per-repo bumps. A Bancolini-local copy avoids all three at the cost of keeping two copies aligned.
- Ref choice is the propagation knob on both platforms: branch = instant fleet-wide change (and fleet-wide breakage); tag/SHA = reviewed per-repo bumps, which Renovate (not Dependabot) can automate on both platforms; Dependabot can bump reusable-workflow refs on GitHub but not service images and nothing on GitLab.
- Renovate is the only bot that sees service images in GitHub workflows and GitLab CI and, with a regex manager, a plain versions file; on Bancolini it must be self-hosted (a scheduled pipeline, which also ties in with the "scheduled pipelines on GitLab" open point of #23).
- The host app (MyTask IMAS) and `thecore_devcontainer/docker/docker-compose.yml` hold the same literals; whatever mechanism is picked, they stay consumers that a check or Renovate rule must cover (Dependabot's `docker-compose` ecosystem can bump the devcontainer compose file).
- GitLab CE 19.5.6 has everything needed (components GA 17.0, `include:integrity` 17.9, `include:cache` GA 19.0).

## Sources

- [GH-reuse] GitHub Docs, Reuse workflows: https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows (and https://docs.github.com/en/actions/sharing-automations/reusing-workflows)
- [GH-ref] GitHub Docs, Reusable workflows reference: https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations
- [GH-ctx] GitHub Docs, Contexts, "Context availability": https://docs.github.com/en/actions/reference/workflows-and-actions/contexts
- [GH-composite] GitHub Docs, Metadata syntax, `runs` for composite actions: https://docs.github.com/en/actions/reference/workflows-and-actions/metadata-syntax
- [GH-vars] GitHub Docs, Variables (configuration variables levels): https://docs.github.com/en/actions/reference/workflows-and-actions/variables
- [GL-yaml] GitLab Docs, CI/CD YAML syntax, `include`: https://docs.gitlab.com/ci/yaml/
- [GL-inc] GitLab Docs, Use CI/CD configuration from other files: https://docs.gitlab.com/ci/yaml/includes/
- [GL-comp] GitLab Docs, CI/CD components: https://docs.gitlab.com/ci/components/
- [GL-where] GitLab Docs, Where variables can be used: https://docs.gitlab.com/ci/variables/where_variables_can_be_used/
- [GL-mirror] GitLab Docs, Pull mirroring: https://docs.gitlab.com/user/project/repository/mirror/pull/
- [GL-outbound] GitLab Docs, Filtering outbound requests: https://docs.gitlab.com/security/webhooks/
- [DB-eco] GitHub Docs, Dependabot supported ecosystems: https://docs.github.com/en/code-security/dependabot/ecosystems-supported-by-dependabot/supported-ecosystems-and-repositories
- [RN-gha] Renovate, github-actions manager: https://docs.renovatebot.com/modules/manager/github-actions/
- [RN-glci] Renovate, gitlabci manager: https://docs.renovatebot.com/modules/manager/gitlabci/
- [RN-glinc] Renovate, gitlabci-include manager: https://docs.renovatebot.com/modules/manager/gitlabci-include/
- [RN-regex] Renovate, custom managers (regex): https://docs.renovatebot.com/modules/manager/regex/
- Local: `vendor/submodules/*/.github/workflows/gempush.yml`, `vendor/submodules/*/.gitlab-ci.yml`, `thecore_generators/lib/generators/thecore/atom/atom_generator.rb`, `thecore_devcontainer/docker/docker-compose.yml`, `thecore_devcontainer/scripts/gem-compile.sh`, MyTask IMAS backend `.gitlab-ci.yml`; GitLab version from `https://devops.bancolini.com/api/v4/version` via `glab api version`.
