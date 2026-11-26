# Security scanners that work on an ATOM in CI

Research for [#24](https://github.com/gabrieletassoni/thecore/issues/24) (map [#23](https://github.com/gabrieletassoni/thecore/issues/23)), 2026-11-26. Facts only; the choice is [#26](https://github.com/gabrieletassoni/thecore/issues/26)'s.

**Question.** Which security scanners actually work on an ATOM (a Rails engine tested through its Dummy app, `Gemfile.lock` resolved fresh in CI), on both GitHub Actions and Bancolini GitLab CI (CE), and what does each catch that the others don't?

**Method.**
- Primary sources: the tools' docs and source code, linked inline.
- Local runs on copies (`git archive HEAD`) of four ATOM checkouts from the MyTask IMAS host (`vendor/submodules/`): `thecore_auth_commons`, `model_driven_api`, `thecore_ui_commons`, `mytask`. Tools: brakeman 8.1.1, bundler-audit 0.9.3, semgrep with GitLab's `sast-rules` Ruby rules (`rules/lgpl-cc/ruby`), Ruby 3.3.
- The GitHub code-scanning API on three public base ATOMs.
- Trivy was **not** run: the container had no Docker socket. Its rows below come from its docs only.

Marks: **[run]** means observed locally. **[api]** means read from the GitHub API. **[inference]** is my reasoning, not something a source states.

## Comparison

| Scanner | Runs on an engine? | What only it catches | Noise seen on ATOMs | Runtime | Exit code for blocking | GitHub Actions | GitLab CE |
|---|---|---|---|---|---|---|---|
| **bundler-audit** (`bundle-audit check --update`) | Yes, on the lock that `bundle install` writes in the job. With no lock it exits 1 [run] | Known CVEs in the *resolved* gem versions (ruby-advisory-db), plus `http://`/`git://` gem sources | 0 false positives. Every hit is a real advisory on a resolved version. 17 on a stale local lock pinned to Rails 7.2.4 [run] | ~1 s + advisory DB clone [run] | Non-zero on any vulnerability. `.bundler-audit.yml` `ignore:` / `--ignore` for exceptions | `gem install` in the job | Same |
| **brakeman** (at the engine root) | Yes, without `--force`: it only needs an `app/` dir. ATOMs with no `app/` exit **4** unless `--force` | Rails data-flow patterns: SQL/command injection, unsafe reflection, mass assignment, CSRF settings. Rails/Ruby EOL and version-specific Rails CVEs **if** a lock is present | auth_commons 1 (EOLRails), model_driven_api 0 (+1 ignored), ui_commons 0 (+1 ignored), mytask 7 Medium "SQL injection" [run] | 1–2 s per ATOM [run] | 0 clean, **3** warnings, 4 no app, 5 not latest, 7 errors, 8 ignore entry without note, 9 obsolete ignore entries. `-w`, `--except`, `config/brakeman.ignore` | `gem install` in the job | Same (GitLab's own Brakeman analyzer is gone since 17.0) |
| **brakeman pointed at `test/dummy`** | Runs, but scans the wrong code | Nothing useful: the engine's code is outside the scan, and the Rails version is guessed as "4.x" | 1 warning on the Dummy app's own controller [run] | ~1 s | as above | — | — |
| **Trivy `fs`** | Yes, if the lock exists: in `fs`/`repo` mode it reads `Gemfile.lock` only. `.gemspec` is read only in `image`/`rootfs` mode, without transitive deps | Second advisory source (GitHub Advisory DB + ruby-advisory-db). Also secret and misconfig scanners (Dockerfile, YAML) in the same binary | not measured | not measured (DB download on every run unless cached) | **0 even with findings** unless `--exit-code 1`; `--severity` limits what fails | Action or binary | `aquasec/trivy` image job |
| **CodeQL** (default setup) | Yes, already on and `configured` on the base ATOMs, weekly + on pushes [api] | Interprocedural taint analysis (Ruby on Rails modeled). Also GitHub Actions workflow issues (`actions/missing-workflow-permissions`) | Also scans `test/dummy`: 2 high `rb/csrf-protection-not-enabled` on Dummy controllers in auth_commons/model_driven_api. 4–5 open alerts per ATOM, untriaged [api] | GitHub-side | It is not a job exit code. It only blocks a **PR** through a "Require code scanning results" ruleset (severity thresholds). Nothing blocks a push to `release/3` or the gem publish | Yes (public repos free) | **No**: the CodeQL CLI licence forbids CI use on non-open-source code without a paid GHAS licence, and SPOT ATOMs are closed-source |
| **GitLab SAST** (Semgrep + GitLab rules) | Yes, already on in SPOT ATOM CI. The Ruby rules are ports of Brakeman checks (`mappings/brakeman.yml`) | Nothing Brakeman lacks, as far as the rule mapping shows [inference]. Its value is a second engine with per-line `# nosemgrep` exceptions | 0 findings on auth_commons with GitLab's Ruby rules [run] | ~5 s locally [run] + image pull | Job stays **green** on findings. On Free/CE you get only the JSON report artifact | Semgrep CLI could run there, but not GitLab's template | Yes (template) |
| **GitLab Secret Detection** (Gitleaks) | Yes (repo-agnostic) | Committed secrets in the pushed commit range. History only with `SECRET_DETECTION_HISTORIC_SCAN` | not measured on ATOMs | short | Job green on findings. Free/CE: JSON report only | Equivalent: GitHub secret scanning + push protection (repo setting) | Yes (template) |
| **`script/security_summary.rb`** | n/a (reads reports) | Makes the CE reports visible: lists findings and exits 1 on any finding **or a missing report** | — | instant | 0 / 1 | Not needed (GitHub shows CodeQL/secret alerts) | Yes. Needs instance artifacts enabled |

## Findings

### bundler-audit

- It checks `Gemfile.lock` for vulnerable versions and insecure sources, and `--update` refreshes ruby-advisory-db first ("useful for CI runs"). Ignores go in `.bundler-audit.yml` or `--ignore`. Source: [bundler-audit README](https://github.com/rubysec/bundler-audit#readme).
- Exit codes: 1 when vulnerabilities are found [run, 17 advisories on a Rails 7.2.4 lock]. Also 1 with the message `Could not find "Gemfile.lock"` when there is no lock [run]. A job that forgets `bundle install` therefore fails loudly instead of passing empty.
- It audits **only what was resolved**. In an ATOM that lock is the dev resolution, steered by the ATOM's own `Gemfile` pins (e.g. a local `thecore_auth_commons` checkout pins `railties ~> 7.2.4`). Two consequences [inference]:
  - A host app resolves the same gemspec differently, so the ATOM's result is not the host's.
  - A gemspec whose floor *allows* a vulnerable version (e.g. `>= 7.2`) is never flagged. No scanner in this table checks constraint floors. Trivy reads `.gemspec` only in image/rootfs mode, without transitive deps ([Trivy language coverage](https://trivy.dev/latest/docs/coverage/language/), [Ruby page](https://trivy.dev/latest/docs/coverage/language/ruby/)).
- This is the tool the nightly with fresh resolution exists for. The host's CI already runs it the same way, blocking only in the schedule (host `.gitlab-ci.yml`, `docs/agents/security.md`; same in `samples/.gitlab-ci.yml` and `samples/.github/workflows/security.yml`).

### brakeman

- It refuses only when the path has no `app/` dir: `if (!@app_tree.root || !@app_tree.exists?("app")) && !options[:force_scan]` raises `NoApplication` → exit 4 ([`lib/brakeman/scanner.rb`](https://github.com/presidentbeef/brakeman/blob/main/lib/brakeman/scanner.rb)). Every engine with `app/` therefore scans at its root without `--force` [run on four ATOMs]. ATOMs here with no `app/` are `thecore_download_documents` and `thecore_generators`: they need `--force` or no Brakeman.
- The engine's `test/dummy` is **not** in the scan, because paths are `app/**/controllers` etc. under the root [run: 2 controllers on auth_commons, the engine's own]. Pointing Brakeman at `test/dummy` instead scans only the Dummy app and reports "Rails Version: 4.x" [run]. That is not useful.
- **Rails version detection needs the lock.** It reads `Gemfile`/`Gemfile.lock` (and the gemspec) ([`scanner.rb` `process_gems`](https://github.com/presidentbeef/brakeman/blob/main/lib/brakeman/scanner.rb)), and otherwise guesses from the directory layout. The docs say the same: version-specific checks "rely on knowing the exact version ... This shouldn't be a problem with any modern Rails app using a `Gemfile.lock`" ([OPTIONS.md](https://github.com/presidentbeef/brakeman/blob/main/OPTIONS.md)). Observed [run]:
  - `model_driven_api` without a lock: "4.x".
  - `model_driven_api` with its lock: "8.1.4.1".
  - `mytask` without a lock: "Unknown".
  - `auth_commons` without a lock, but with a `railties` pin in its Gemfile: "7.2.4" plus an EOLRails warning.
  
  So Brakeman belongs **after** `bundle install` in an ATOM job [inference].
- Exit codes are constants in [`lib/brakeman.rb`](https://github.com/presidentbeef/brakeman/blob/main/lib/brakeman.rb): 3 warnings, 4 no app, 5 not latest (`--ensure-latest`), 6 missing checks, 7 errors, 8 ignore entry without note (`--ensure-ignore-notes`), 9 obsolete ignore entries. Non-zero on warnings or errors is the default ([README](https://github.com/presidentbeef/brakeman#readme)); `--no-exit-on-warn` turns it off.
- EOLRails/EOLRuby are **date-driven**: a release can turn red with no code change [run: auth_commons, "Support for Rails 7.2.4 ended on 2026-08-09"]. They can be dropped with `--except EOLRails,EOLRuby` [run: exit 0].
- Existing exceptions already live where Brakeman looks by default (`config/brakeman.ignore`): `model_driven_api`, `thecore_ui_commons`, `thecore_ui_rails_admin` [run: "Ignored Warnings: 1"].
- GitLab removed its own Brakeman SAST analyzer in 17.0, replaced by Semgrep with GitLab-managed rules ([GitLab SAST analyzers](https://docs.gitlab.com/user/application_security/sast/analyzers/)). Running Brakeman on GitLab therefore means a plain `gem install brakeman` job, which is what the host already does.

### Trivy

- Ruby: `Gemfile.lock` is read in filesystem and repository mode. `.gemspec` is read only in image and rootfs mode and "doesn't contain transitive dependencies" ([coverage table](https://trivy.dev/latest/docs/coverage/language/), [Ruby](https://trivy.dev/latest/docs/coverage/language/ruby/)).
- Advisory sources for RubyGems: ruby-advisory-db **and** the GitHub Advisory Database ([vulnerability scanner](https://trivy.dev/latest/docs/scanner/vulnerability/)). bundler-audit uses only ruby-advisory-db. The overlap is large [inference: the two databases mostly mirror each other].
- "By default, Trivy exits with code 0 even when security issues are detected"; `--exit-code` changes that, filtered by `--severity` ([Others](https://trivy.dev/latest/docs/configuration/others/)).
- Its extra value on an ATOM would be its secret and misconfig scanners. Those overlap with GitLab Secret Detection / GitHub secret scanning [inference]. In this stack Trivy is already used, on images only (`thecore_devcontainer`, per the host's `docs/agents/security.md`).

### CodeQL

- Ruby is supported (up to 3.3; `.rb`, `.erb`, `.gemspec`, `Gemfile`), with Ruby on Rails among the modeled frameworks ([supported languages](https://codeql.github.com/docs/codeql-overview/supported-languages-and-frameworks/)). Default setup is available when the repo "is publicly visible, or GitHub Code Security is enabled" ([default setup](https://docs.github.com/en/code-security/code-scanning/enabling-code-scanning/configuring-default-setup-for-code-scanning)).
- State on the base ATOMs [api]: `thecore_auth_commons`, `model_driven_api` and `thecore_ui_commons` are public, `configured`, schedule `weekly`, languages `ruby`+`actions` (+JS/TS on ui_commons). Open alerts, all untriaged:
  - **auth_commons** (5): 2× `rb/csrf-protection-not-enabled` on `test/dummy` controllers, 2× `rb/clear-text-storage-sensitive-data` in `lib/thecore_auth_commons.rb`, 1× `actions/missing-workflow-permissions` on `gempush.yml`.
  - **model_driven_api** (5): 4× `rb/csrf-protection-not-enabled` (3 on API controllers, which are JWT-authenticated so likely expected [inference]; 1 on `test/dummy`), 1× `actions/missing-workflow-permissions`.
  - **ui_commons** (4): `rb/csrf-protection-not-enabled`, 2× `js/functionality-from-untrusted-source` on `swagger.html.erb`, 1× `actions/missing-workflow-permissions`.
- CodeQL is the only scanner here that looks at **GitHub workflow files** and at the Dummy app [api].
- Blocking: code scanning blocks **pull requests** through the "Require code scanning results" branch ruleset, with alert/security-severity thresholds ([merge protection](https://docs.github.com/en/code-security/code-scanning/managing-your-code-scanning-configuration/set-code-scanning-merge-protection)). The ATOMs' release path is a push to `release/3` that `gempush.yml` publishes from, and nothing there waits for CodeQL [inference from the docs and the workflow layout]. Gating a release on it would need an explicit CodeQL workflow (advanced setup) in the publish job's `needs:`, or an API check of open alerts.
- GitLab: the [CodeQL CLI licence](https://github.com/github/codeql-cli-binaries/blob/main/LICENSE.md) allows CI use only on open-source codebases, unless you hold a paid GitHub Advanced Security licence. That rules it out for the SPOT ATOMs (closed-source, Bancolini GitLab).

### GitLab SAST and Secret Detection

- SAST: on Free/Premium you get "basic scanning with open-source analyzers" and the downloadable JSON report. MR findings and vulnerability management are Ultimate ([SAST](https://docs.gitlab.com/user/application_security/sast/)). Ruby "including Ruby on Rails" is fully supported through the Semgrep analyzer with GitLab rules. `SAST_EXCLUDED_PATHS` defaults to `spec, test, tests, tmp`, so `test/dummy` is excluded unless the variable is overridden.
- The Ruby rules in [`sast-rules`](https://gitlab.com/gitlab-org/security-products/sast-rules) are mapped one-to-one to Brakeman warning codes (`mappings/brakeman.yml`, 40 rule files under `rules/lgpl-cc/ruby`). Run locally on `thecore_auth_commons`: 0 findings, ~5 s [run].
- Secret Detection (Gitleaks) is available in all tiers. Free gets the JSON report artifact. By default it scans the pushed commit range, and `SECRET_DETECTION_HISTORIC_SCAN=true` scans all history, recommended once ([pipeline secret detection](https://docs.gitlab.com/user/application_security/secret_detection/pipeline/)).
- Neither template job fails on findings. That is why `security_summary.rb` exists: it exits 1 on any finding or a missing report (`samples/script/security_summary.rb`). It is GitLab-report specific, and it can only make a pipeline orange or red if the job is not `allow_failure`.
- GitLab Dependency Scanning is **Ultimate** only ([dependency scanning](https://docs.gitlab.com/user/application_security/dependency_scanning/)). It is not an option on Bancolini CE; bundler-audit (or Trivy) fills that role.

### Unexpected things found along the way

1. **`mytask` has 7 untriaged Brakeman "Possible SQL injection" warnings** (Medium): `app/lib/analytics.rb` (lines 42, 68, 124), `app/lib/analytics_extract_csv.rb` (43, 51), `lib/mytask.rb` (421, 447) [run]. The host's `docs/agents/security.md` records that three Analytics warnings "left with the code when Analytics moved to the `mytask` gem (Odoo #6304), which this host's Brakeman does not scan". Brakeman runs in no SPOT ATOM CI today, so nobody sees these.
2. **Open CodeQL alerts on the base ATOMs are not triaged** (listed above). Among them, `rb/clear-text-storage-sensitive-data` ×2 in `thecore_auth_commons/lib/thecore_auth_commons.rb`, and `actions/missing-workflow-permissions` on every `gempush.yml` checked.
3. **Brakeman EOL checks fail on dates.** Any ATOM still pinned to Rails 7.2 goes red as soon as Brakeman runs (Rails 7.2.4 EOL 2026-08-09 per Brakeman).
4. **No scanner checks gemspec floors** (`>= 7.2`, `~> 3.1`) for versions that would allow vulnerable gems in a host. Only the resolved lock is audited.

## What this means for the decision in #26

These are facts to weigh, not choices.

- **Available identically on both platforms**, as a plain job in the devcontainer image: **bundler-audit** and **brakeman** (and Trivy, as a container job). Their exit codes are non-zero on findings (Trivy only with `--exit-code`), so they can gate the release moment and the nightly with the same commands in `gempush.yml` and `.gitlab-ci.yml`. That fits ADR 0006's "equivalent" requirement.
- **Available on one platform only**: **CodeQL** (GitHub, public ATOMs; legally excluded for closed SPOT code on GitLab) and **GitLab SAST + Secret Detection** (GitLab; their GitHub counterparts are CodeQL and secret scanning with push protection, both repository settings, not jobs).
  - Neither of these produces a failing job on its own. GitLab's need `security_summary.rb` without `allow_failure`. CodeQL blocks PRs through a ruleset, not pushes or publishes, unless it is turned into an explicit workflow job.
  - Equivalence across the two CIs can therefore hold for the bundler-audit and brakeman jobs, while the platform-native scanners differ.
- **Order constraints**: bundler-audit and Brakeman both need the job's freshly resolved `Gemfile.lock`. Without it, bundler-audit exits 1, and Brakeman silently loses version-specific checks. So they run after `bundle install`, which the test job already does. Run them in a separate job, and that job pays for its own resolution.
- **Engines without `app/`** (`thecore_download_documents`, `thecore_generators`) make Brakeman exit 4. The standard needs either `--force` or "Brakeman only where `app/` exists".
- **Blocking noise to expect on day one**:
  - Brakeman EOL warnings on any 7.2-pinned ATOM.
  - The 7 mytask SQL warnings.
  - Existing `brakeman.ignore` files already absorb the triaged ones on 3 base ATOMs.
  - CodeQL's Dummy-app CSRF alerts, if CodeQL is ever made blocking.
  - bundler-audit stays at zero false positives, but its findings move with the advisory DB (the reason for the nightly).
- **Overlap**:
  - bundler-audit ≈ Trivy-on-lock for Ruby CVEs. Trivy adds a second DB, plus secret and misconfig scanning.
  - Brakeman ≈ GitLab SAST Ruby rules (a port of the same checks).
  - CodeQL is the only interprocedural analysis, and the only scanner covering GitHub workflow files.
  - Secret scanning is covered natively on both platforms.
- **Runtime is not a constraint**: Brakeman and bundler-audit took 1–2 s each per ATOM locally, Semgrep ~5 s, all excluding image pull and `bundle install`.
