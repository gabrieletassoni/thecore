# Building a Thecore Application from Scratch

A step-by-step walkthrough for creating a complete Thecore application, from an empty folder to a running Rails API with a modular engine.

---

## Before you begin: the Thecore mindset

Thecore is designed around five principles that shape every decision in this walkthrough. Understanding them upfront makes every generated file and folder feel obvious rather than arbitrary.

### Convention over configuration

Every filename, folder, module namespace, and class name follows a predictable pattern. You will never choose where to put a model concern, a migration, or an admin action: Thecore generates it in the right place, with the right name, automatically. This consistency means that any developer familiar with Thecore can open any Thecore project and immediately navigate it without a README.

### High automation

No boilerplate is written by hand. Model, migration, root action, member action, collection action, and ATOM scaffolding are all Rails-native generators (`rails generate model`/`migration`/`thecore:root_action`/`thecore:member_action`/`thecore:collection_action`/`thecore:atom`, all hooked or shipped by the `thecore_generators` gem). Every one of them also has a VS Code context-menu command ("Thecore 3: Add a Model", "Add a DB Migration", "Add a Root Action", "Add a Member Action", "Add a Collection Action", "Create an ATOM"), and each command delegates to the same generator rather than reimplementing it, so the result is identical from either side. ("Add a Collection Action" ships in the first extension release after 3.10.0; with 3.10.0 use the terminal.) Either way, the goal is that a feature domain — model, admin UI, API serialisation, custom endpoints — is ready to be filled with business logic within seconds.

### High standardisation

Every ATOM (modular engine) has the same internal layout. Every model gets the same default API serialisation and admin navigation behaviour with zero generated files, from gem-owned default modules included into `ApplicationRecord` automatically — a per-model `Api::`/`RailsAdmin::` concern exists only once a model needs to override that default (see "Default-first models, concerns only when customizing" in [GUIDE.md §1](GUIDE.md#1-philosophy)). Every root action has the same file structure. This makes the codebase predictable at scale: adding a tenth ATOM feels identical to adding the first one.

### Introspection-based development

Thecore generates code that configures itself by reading the model structure at runtime. Every `ApplicationRecord` subclass gets default JSON serialisation and default admin navigation automatically, from gem-owned default modules — no per-model file required for the common case. When a model needs to differ, an `Api::ModelName` or `RailsAdmin::ModelName` concern overrides just that piece: `Api::ModelName` uses `ModelDrivenApi.smart_merge` to compose the JSON serialisation configuration on top of the default; `RailsAdmin::ModelName` uses `rails_admin do` blocks, loaded dynamically after the default and so free to override it. You add a field to a migration and it appears in the API and admin UI without touching configuration files — whether or not a concern exists for that model.

### Sensible defaults

Everything generated is immediately functional. A new model is visible in the admin UI and serialised in the API before you write a single line of business logic; custom endpoints are added only when a model needs one. Defaults are designed to be correct for the common case and easy to override for the specific case.

---

## What you will build

This walkthrough creates a fictional **Fleet Management** application. It will have:

- A main Rails application (`fleet_app`)
- An ATOM called `Vehicle Registry` that manages vehicles and their assignments
- A root action for a fleet dashboard
- A member action to archive a vehicle

---

## Step 0 — Prerequisites

Make sure you have:

- **Docker** running on your machine
- **Visual Studio Code** with the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension installed
- The **Thecore** VS Code extension installed — see [Installing the Thecore VS Code extension](SETUP_VSCODE.md#installing-the-thecore-vs-code-extension) for all installation options (CLI via `ovsx`, manual `.vsix`, or configuring open-vsx in the Extensions panel). The Microsoft Marketplace is **not recommended** as it may not carry the latest version.

---

## Step 1 — Open the devcontainer

Create an empty folder called `fleet_app` and open it in VS Code.

```
File → Open Folder → select fleet_app
```

VS Code will ask if you want to reopen in a container. If the folder does not already have a `.devcontainer/` directory, generate it first:

> **Right-click the `fleet_app` folder in the Explorer → Thecore 3: Setup Devcontainer**

It asks for the project name (`Fleet App`) and generates:

```
fleet_app/
└── .devcontainer/
    ├── devcontainer.json            ← features, extensions, mounts, initializeCommand, postCreateCommand
    ├── docker-compose.yml           ← app (as user vscode), db (PostgreSQL 15), redis, with healthchecks
    ├── Dockerfile                   ← FROM gabrieletassoni/vscode-devcontainers-thecore:3
    ├── create-db-user.sql           ← run by the db service on its first start
    ├── backend.code-workspace       ← a VS Code workspace file for the app
    ├── heal-stale-containers.sh     ← run on the host by initializeCommand
    ├── link-host-home.sh            ← run by postCreateCommand (Claude Code plugin paths)
    ├── github-accounts.sh           ← run by postCreateCommand (one SSH key per GitHub account)
    ├── check-plugins.sh             ← run by postCreateCommand (warns if the skills plugin is missing)
    └── .thecore-template-version    ← the extension version that wrote this scaffold (see below)
```

The command refuses to run when `.devcontainer/` already exists, so it never overwrites a working
configuration: move the old folder away first if you want a fresh one.

What these files do when the container starts:

- `initializeCommand` runs on the host, before `docker compose up`. It creates the host paths of
  the active bind mounts when they are missing (`~/.claude`, `~/.bundle`, `~/.gem` as directories,
  `~/.claude.json` as `{}`), so a fresh machine never fails on a missing mount source. Then it runs
  `heal-stale-containers.sh`, which removes this project's containers when the Docker network they
  point at was deleted (a `docker network prune`, a Docker upgrade); volumes are kept.
- The `~/.claude`, `~/.claude.json`, `~/.bundle` and `~/.gem` mounts are active, so Claude Code's
  login and plugins and your gem credentials work inside the container without editing JSON. The
  `gh` and `glab` config mounts are commented out: uncomment one (and add its path to
  `initializeCommand`) to reuse that CLI's host login.
- `postCreateCommand` fixes the ownership of `/usr/local/bundle`, runs `bundle update`, then
  `link-host-home.sh`, `github-accounts.sh` and `check-plugins.sh`. It never runs a bare
  `bundle update --bundler` or `--all`, which could write a prerelease Bundler into `Gemfile.lock`.

Then reopen in the container:

```
Ctrl+Shift+P → Dev Containers: Reopen in Container
```

The container starts with Ruby, Rails, Node.js, the Docker CLI (talking to the host's Docker), and all Thecore tooling already installed. Your terminal is now running inside the container.

> **Why a devcontainer?**
> Every developer on the team runs the same binary versions of Ruby, Rails, bundler, Node, and the database driver. There is no "works on my machine" problem. The devcontainer image (`gabrieletassoni/vscode-devcontainers-thecore:3`) is rebuilt and published to Docker Hub on every push to `thecore_devcontainer`'s `release/3` branch and every Sunday, so it always tracks the latest Thecore-compatible toolchain.

> **The "scaffold out of date" message.** `.thecore-template-version` holds the version of the
> extension that ran Setup Devcontainer. The image carries the version of the extension it was
> built with, and every new shell compares the two: when the scaffold is older, it prints a yellow
> warning suggesting you regenerate `.devcontainer/`. Only Setup Devcontainer writes this marker.
> Step 2 below rewrites the other devcontainer files but leaves the marker as it was, so after
> Step 2 the marker no longer says where the files came from. An app created with the bare App
> template (no Step 1) has no marker, and the message never appears. See
> [GUIDE.md §3.1](GUIDE.md#31-setup-the-devcontainer) for how to act on it.

## Alternative: the headless CLI (`thecore setup-dev-container`)

Generating `.devcontainer/` doesn't require VS Code at all: `thecore setup-dev-container --name
"Fleet App"` (thecore_code_extension#39), a terminal binary installed from a clone of
`thecore_code_extension`, produces the identical file tree above from any script or CI job — the
one extension command with no Rails-native generator to delegate to instead. Full reference:
[GUIDE.md §3.1.1](GUIDE.md#311-the-headless-cli-thecore-setup-dev-container).

---

## Step 2 — Create the main application

> **Right-click the `fleet_app` root folder in the Explorer → Thecore 3: Create an App**

Watch the **Thecore: Create App** output channel. The command shells out to the [App application
template](#alternative-the-app-application-template-cli-no-vs-code-needed) (the box just below
this one) for the bulk of the work, then adds app-specific runtime config of its own:

| Step | What happens |
|---|---|
| Pre-flight checks | Verifies that a folder is open and that at most one folder is open in the window (it does not check that the folder is empty: the `.devcontainer/` from Step 1 is expected), that `ruby`, `rails` and `bundle` are available, and that the folder isn't already a Rails app (if it is, the command stops without a message) |
| App application template | `rails new . --database=postgresql --asset-pipeline=sprockets --skip-git -m <app_template.rb URL>`, non-interactive, installers always run — see the box below for everything this one call does: the Gemfile stack with its security floors (**`thecore_generators` itself** included), Rails' root `Dockerfile` and `bin/docker-entrypoint` removed, the eight `.devcontainer/*` files rewritten from the `thecore` samples, `.gitlab-ci.yml`, `.github/workflows/ci.yml` and `security.yml`, `script/security_summary.rb` and its test, `CLAUDE.md`, `AGENTS.md`, `docs/agents/`, the test-database rule in `test/test_helper.rb`, `vendor/submodules/`/`vendor/external/`, and the full installer chain (`devise:install`, `rails_admin:install`, `active_storage:install`, `action_text:install`, `action_mailbox:install`, `cancan:ability`, `erd:install`) |
| `.gitignore` | Overwrites the default Rails gitignore with a comprehensive Thecore-specific one — the template doesn't touch this file |
| Sidekiq | Creates `config/sidekiq.yml` with dynamic queue configuration |
| Version file | Creates `version` containing `3.0.1` |
| `development.rb` patch | Sets `raise_on_missing_callback_actions = false` |
| Database | Runs `db:drop` (safety net), `db:create`, `db:migrate`, `thecore:db:seed`, on the database the running container's `DATABASE_URL` names (Step 1's) |
| Vendor directories | Creates `vendor/custombuilds/`, `vendor/deploytargets/` (`vendor/submodules/` already exists — the template created it) |
| `.dockerignore` | Removes the one `rails new` writes. The Thecore Dockerfile builds the image with `ADD .`, so without it the image gets the whole CI checkout. The bare App template (box below) keeps it |
| `git init` | Initialises the repository with a `main` branch and a single "Initial commit" — the template never touches git |

When the output channel shows `✅ Thecore 3 App created successfully.` the application is fully wired and the database is seeded with the default Thecore admin user. `thecore_generators` is already in the Gemfile at this point — no manual step needed before Step 4 below.

**Rebuild the container once.** The App template replaced `devcontainer.json` and
`docker-compose.yml` with the `thecore` samples, which differ from Step 1's in three ways: the
container is named `Thecore App`, the workspace is mounted at `/workspaces/app` instead of
`/workspaces/project/backend`, and `DATABASE_URL` names the database `app_dev` instead of the one
Step 1 derived from the project name. The running container still has Step 1's settings, so run
**Dev Containers: Rebuild Container**, then create and seed the new database once:

```bash
bin/rails db:create db:migrate thecore:db:seed
```

`backend.code-workspace` and `.thecore-template-version` are left as Step 1 wrote them: the
template only writes the eight files it fetches. Commit the result.

**What you now have:**

```
fleet_app/
├── .devcontainer/                ← eight files from the App template's samples/devcontainer/ fetch,
│                                    plus Step 1's backend.code-workspace and marker
├── .github/workflows/            ← ci.yml and security.yml, from the App template's samples/ fetch
├── .gitlab-ci.yml                ← from the App template's samples/ fetch (with the security jobs)
├── script/security_summary.rb    ← from the App template's samples/ fetch (test in test/script/)
├── AGENTS.md                     ← from the App template's samples/ fetch (points to CLAUDE.md)
├── CLAUDE.md                     ← from the App template's samples/ fetch
├── docs/agents/                  ← from the App template's samples/ fetch (tracker, labels, domain)
├── app/
│   ├── models/
│   │   └── concerns/            ← app-level concerns (empty for now)
│   └── ...
├── config/
│   ├── sidekiq.yml              ← Sidekiq queue configuration
│   └── ...
├── db/
├── test/test_helper.rb          ← forces the test database when DATABASE_URL is set
├── vendor/
│   ├── custombuilds/            ← custom Dockerfiles per deploy target (empty for now)
│   ├── deploytargets/           ← per-installation deploy configuration, committed (empty for now)
│   ├── submodules/              ← ATOMs will live here
│   └── external/                ← reference repos
└── version                      ← semantic version seed
```

> **Sensible defaults in action:** the admin UI (`rails_admin`), authentication (`devise`), authorisation (`cancancan`), background jobs (`sidekiq`), and REST API (`model_driven_api`) are all configured and functional before you write a single line of business logic.

> **Note on `raise_on_missing_callback_actions`:** the command automatically sets this to `false` in `config/environments/development.rb`. This prevents Rails from raising errors on before/after action callbacks that are handled by Thecore's engine, which is the correct default for Thecore development.

---

## Alternative: the App application template (CLI, no VS Code needed)

Everything Step 2 just did can also be done from a plain terminal, with `ruby`/`rails` available
(inside the devcontainer from Step 1, or anywhere else) — no VS Code, no extension. This is the
App application template, a genuine Rails application template (`thecore_generators`'s own
`lib/templates/app_template.rb`), invoked via `rails new -m` instead of `rails generate`. Skip
this box if you already did Step 2 the VS Code way; the rest of this walkthrough works either
way, since Steps 3 onward only assume `fleet_app` already exists, not how it was created.

```bash
# Inside the Step 1 devcontainer, on the folder it opened:
rails new . --database=postgresql --asset-pipeline=sprockets \
  -m https://raw.githubusercontent.com/gabrieletassoni/thecore_generators/release/3/lib/templates/app_template.rb

# Anywhere else, creating the folder (every .devcontainer/* file is then a `create`):
rails new fleet_app --database=postgresql --asset-pipeline=sprockets \
  -m https://raw.githubusercontent.com/gabrieletassoni/thecore_generators/release/3/lib/templates/app_template.rb
```

Illustrative, not a verbatim capture — Thor logs more status lines per action than shown here
(`route`, an extra line per `generate` call) and some are abbreviated with `...`. Run inside the
Step 1 devcontainer, the eight `.devcontainer/*` files already exist: the two that differ from the
samples are overwritten (`force`), the six that are byte-identical are left alone (`identical`):

```
      create  Gemfile
      ...
       apply  .../thecore_generators/lib/templates/app_template.rb
     gemfile    devise
     gemfile    cancancan
     gemfile    rails_admin
     gemfile    sassc-rails
     gemfile    model_driven_api (~> 3.13, >= 3.13.1)
     gemfile    thecore_ui_rails_admin (~> 3.8, >= 3.8.7)
     gemfile    thecore_backend_commons (~> 3.9, >= 3.9.1)
     gemfile    thecore_auth_commons (~> 3.6, >= 3.6.3)
        gsub    Gemfile                       (rails ~> 7.2, >= 7.2.4)
        gsub    Gemfile                       (puma >= 7.2.1)
     gemfile    redis (< 6)
     gemfile    connection_pool (~> 2.4)
     gemfile    rails-erd
     gemfile    thecore_generators (~> 3.13)
      append    Gemfile                       (the optional ecosystem gems, commented out)
      create    vendor/submodules
      create    vendor/submodules/.keep
      create    vendor/external
      create    vendor/external/.keep
      remove    Dockerfile
      remove    bin/docker-entrypoint
       force    .devcontainer/devcontainer.json
       force    .devcontainer/docker-compose.yml
   identical    .devcontainer/Dockerfile
   identical    .devcontainer/create-db-user.sql
   identical    .devcontainer/link-host-home.sh
   identical    .devcontainer/check-plugins.sh
   identical    .devcontainer/heal-stale-containers.sh
   identical    .devcontainer/github-accounts.sh
       chmod    .devcontainer/link-host-home.sh
       ...
      create    .gitlab-ci.yml
      create    .github/workflows/ci.yml
      create    .github/workflows/security.yml
      create    script/security_summary.rb
      create    test/script/security_summary_test.rb
      create    CLAUDE.md
      create    AGENTS.md
      create    docs/agents/issue-tracker.md
      create    docs/agents/triage-labels.md
      create    docs/agents/domain.md
      insert    test/test_helper.rb
  Run `bundle install` and the standard installer generators (devise, rails_admin,
  active_storage, action_text, action_mailbox, cancan, erd) now? (y/n) y
         run  bundle install
    generate  devise:install
    ...
    generate  rails_admin:install
    ...
       rails  active_storage:install
       ...
```

Answering `y` to the last prompt runs the same installer chain Step 2's table describes
(`devise:install`, `rails_admin:install`, `active_storage:install`, `action_text:install`,
`action_mailbox:install`, `cancan:ability`, `erd:install`) — answer `n` instead to bootstrap
offline and run `bundle install` plus those generators by hand once you have connectivity; the
Gemfile and every file listed above are written either way, regardless of the answer.

**Non-interactively** (CI, scripted setups — no prompt to answer at all):

```bash
THECORE_APP_TEMPLATE_NON_INTERACTIVE=1 THECORE_APP_TEMPLATE_RUN_INSTALLERS=true \
  rails new fleet_app --database=postgresql --asset-pipeline=sprockets \
  -m https://raw.githubusercontent.com/gabrieletassoni/thecore_generators/release/3/lib/templates/app_template.rb
```

`THECORE_APP_TEMPLATE_RUN_INSTALLERS` (`"true"`/`"false"`) is required whenever
`THECORE_APP_TEMPLATE_NON_INTERACTIVE` is set — the template aborts with a clear message naming
the missing variable rather than guessing whether to run the installer chain unattended.

**Compared to Step 2's "Thecore 3: Create an App"**: the same underlying template — "Create an
App" shells out to this exact `rails new -m` invocation, non-interactively, with the installers
always on. What Step 2 adds on top, that this bare template alone doesn't: `config/sidekiq.yml`,
the `version` file, a `development.rb` patch, the Thecore `.gitignore`, database bootstrap
(`db:create`/`migrate`/`thecore:db:seed`), `vendor/custombuilds/`/`vendor/deploytargets/`, the
removal of `.dockerignore` (kept here, so the image build skips what it lists), and git init/commit
— see Step 2's own table above for the full list. The template never writes
`backend.code-workspace` or `.thecore-template-version`, so without Step 1 the app has neither
(and no "scaffold out of date" message). Run this box directly when you only need the
generic Rails/Gemfile/CI/devcontainer/CLAUDE.md core, without the app-specific runtime config
Step 2 layers on top.

**What it deliberately doesn't do**: this produces a generic, blank app — no customer-specific
customization, no pre-wired `vendor/submodules/` content (Step 3 below adds a real ATOM by hand
either way; the box just below it shows the terminal-only alternative for that too). See
[ADR 0005](https://github.com/gabrieletassoni/thecore/blob/release/3/docs/adr/0005-app-template-scoped-to-rails-new-m-assets-sourced-from-thecore-samples.md)
in `docs/adr/`. Full reference: [GUIDE.md §3.2.1](GUIDE.md#321-the-app-application-template-rails-new--m).

---

## Step 3 — Create the first ATOM

The main application is intentionally thin. Feature domains live in ATOMs. Create one for vehicle management.

> **Right-click the `fleet_app` root folder in the Explorer → Thecore 3: Create an ATOM**

Fill in the fields as they appear:

| Field | Format | Example value |
|---|---|---|
| Name | Free text (auto-converted to snake_case) | `Vehicle Registry` |
| Summary | Short sentence | `Manages the vehicle fleet and assignments` |
| Description | Full description | `Provides models, admin UI, and API endpoints for vehicle lifecycle management` |
| Author | Full name | `Fleet Corp Engineering` |
| Email | Valid email | `dev@fleetcorp.example.com` |
| URL | Valid URL | `https://github.com/fleetcorp/vehicle_registry` |

The command collects these six fields via the dialogs above, then shells out to
`bundle install && rails generate thecore:atom` with them as
`--non-interactive --summary=... --description=... --author=... --email=... --url=...` flags —
the exact same generator the box just below this one invokes directly from a terminal. It:

1. Creates the Rails engine at `vendor/submodules/vehicle_registry` (`rails plugin new ... --full
   --database=postgresql --skip-ci`, run by the generator): the dummy app under `test/dummy/` runs
   on PostgreSQL, and Rails' own SQLite CI and `dependabot.yml` are not generated
2. Sets the gemspec: your author, email, homepage, summary and description, `rails ~> 7.2`, the
   `model_driven_api ~> 3.9`/`thecore_ui_rails_admin ~> 3.8` dependencies, and
   `allowed_push_host` `https://rubygems.org` (the dialogs don't ask for a gem server: for a
   private one, use the terminal generator's `--gem-host`, see the box below)
3. Creates the full Thecore ATOM folder structure, the CI (`.github/workflows/gempush.yml` and
   `.gitlab-ci.yml`), `script/security_summary.rb` with its test, and a `CLAUDE.md`
4. Makes the dummy app use `vehicle_registry_<RAILS_ENV>` databases, even when `DATABASE_URL`
   (set by the devcontainer to the app's development database) is present
5. `git init`s the new ATOM on branch `release/3`, with one local commit
6. Adds `gem "vehicle_registry", path: "vendor/submodules/vehicle_registry"` to the main app `Gemfile`

**What is generated inside the ATOM:**

```
vendor/submodules/vehicle_registry/
├── vehicle_registry.gemspec           ← gem metadata (author, deps, allowed_push_host)
├── lib/vehicle_registry/version.rb    ← bump it to publish (see Step 12)
├── CLAUDE.md                          ← from thecore's samples/ATOM_CLAUDE.md
├── .github/workflows/gempush.yml      ← publishes to RubyGems.org from release/3
├── .gitlab-ci.yml                     ← publishes when version.rb changes + SAST/Secret Detection
├── script/security_summary.rb         ← GitLab CE security summary (test in test/script/)
├── .rubocop.yml                       ← rubocop-rails-omakase, as rails plugin new writes it
├── app/
│   ├── models/
│   │   └── concerns/
│   │       ├── api/                   ← Api:: concerns go here
│   │       └── rails_admin/           ← RailsAdmin:: concerns go here
│   ├── assets/
│   │   ├── javascripts/
│   │   └── stylesheets/
│   └── views/rails_admin/main/        ← action templates go here
├── config/
│   ├── initializers/
│   │   ├── after_initialize.rb        ← hook to require root/member actions
│   │   ├── add_to_db_migration.rb     ← registers db/migrate with Rails
│   │   ├── assets.rb                  ← asset precompile declarations
│   │   └── abilities.rb               ← CanCan ability class stub (only with the API/Admin dependencies)
│   └── locales/
│       ├── en.yml                     ← English i18n stubs
│       └── it.yml                     ← Italian i18n stubs
├── db/
│   ├── migrate/                       ← ATOM migrations (written here directly by rails generate model/migration)
│   └── seeds.rb                       ← ATOM seed data
├── lib/
│   ├── root_actions/                  ← rails_admin main menu sections
│   ├── member_actions/                ← rails_admin per-row buttons
│   └── collection_actions/            ← rails_admin collection-level actions
└── test/dummy/                        ← the app the ATOM's tests boot, on PostgreSQL
```

Its own tests run from its directory, on its own test database:

```bash
cd vendor/submodules/vehicle_registry
bundle install && bin/rails db:create && bin/rails test
```

> **Why are migrations inside the ATOM?**
> The `add_to_db_migration.rb` initialiser adds the ATOM's `db/migrate/` path to Rails' migration lookup. This means `rails db:migrate` in the main app finds and runs all ATOM migrations automatically. Keeping them inside the ATOM makes the domain self-contained: you can add this ATOM to another project and its schema comes with it.

> **Convention in action:** note that you never chose any of these paths or filenames. The name `Vehicle Registry` became `vehicle_registry` everywhere — folder name, gemspec name, Gemfile entry, module namespace — without any additional input.

---

## Alternative: the `thecore:atom` generator (CLI, no VS Code needed)

Everything Step 3 just did can also be done from a plain terminal — no VS Code, no extension.
This is `thecore:atom`, a real Rails generator (`thecore_generators`'s
`Thecore::Generators::AtomGenerator`), invoked via `rails generate` like any other. Skip this
box if you already did Step 3 the VS Code way; Step 4 onward only assumes `vehicle_registry`
already exists, not how it was created. Run it from `fleet_app`'s own root — unlike every other
`thecore:*` generator, it takes no `--atom=NAME`, since creating a *new* ATOM only makes sense
from the app that will contain it.

```bash
bundle exec rails generate thecore:atom vehicle_registry
```

Note the name itself: unlike "Create an ATOM"'s free-text input (`Vehicle Registry` → converted
to `vehicle_registry` for you), the generator's `NAME` argument must already be a valid,
already-snake_case gem name — you type `vehicle_registry` directly.

Illustrative, not a verbatim capture — Thor logs one status line per file/directory created
(a dozen-plus `.keep` files alone), and the nested `rails plugin new` subprocess prints its own
full "create" log on top of that; both are elided here with `...`:

```
$ bundle exec rails generate thecore:atom vehicle_registry
Enter the summary of the ATOM, i.e. TCP Debugger:
Manages the vehicle fleet and assignments
Enter the description of the ATOM, i.e. TCP Debugger:
Provides models, admin UI, and API endpoints for vehicle lifecycle management
Enter the author of the ATOM, i.e. Alchemic IT:
Fleet Corp Engineering
Enter the email of the ATOM author:
dev@fleetcorp.example.com
Enter the url of the ATOM:
https://github.com/fleetcorp/vehicle_registry
Include model_driven_api/thecore_ui_rails_admin as dependencies? [yes, no] yes
       run  bundle exec rails plugin new vehicle_registry -fG --skip-gemfile-entry --skip-hotwire --full --database=postgresql --skip-ci from "vendor/submodules"
      ...
       force  vendor/submodules/vehicle_registry/test/dummy/config/database.yml
      append  vendor/submodules/vehicle_registry/test/dummy/config/boot.rb
      create  vendor/submodules/vehicle_registry/test/dummy/app/models/ability.rb
      create  vendor/submodules/vehicle_registry/test/dummy/config/initializers/devise.rb
      create  vendor/submodules/vehicle_registry/db/migrate/.keep
      ...
      create  vendor/submodules/vehicle_registry/config/initializers/after_initialize.rb
      create  vendor/submodules/vehicle_registry/config/initializers/abilities.rb
      create  vendor/submodules/vehicle_registry/db/seeds.rb
      create  vendor/submodules/vehicle_registry/config/locales/en.yml
      create  vendor/submodules/vehicle_registry/config/locales/it.yml
      create  vendor/submodules/vehicle_registry/.github/workflows/gempush.yml
      create  vendor/submodules/vehicle_registry/.gitlab-ci.yml
      create  vendor/submodules/vehicle_registry/script/security_summary.rb
      create  vendor/submodules/vehicle_registry/test/script/security_summary_test.rb
      append  vendor/submodules/vehicle_registry/Gemfile
       force  vendor/submodules/vehicle_registry/vehicle_registry.gemspec
      create  vendor/submodules/vehicle_registry/CLAUDE.md
         run  git init -q -b release/3 from "vendor/submodules/vehicle_registry"
         run  git add -A from "vendor/submodules/vehicle_registry"
         run  git ... commit -q -m "Initial commit" from "vendor/submodules/vehicle_registry"
  next_steps  vehicle_registry is git-initialized locally with one commit, but has no remote yet. To finish wiring it in:
                1. Create a repository for it on the git host of your choice (GitHub, GitLab, ...)
                2. cd <path-to-fleet_app>/vendor/submodules/vehicle_registry && git remote add origin <remote-url> && git push -u origin release/3
                3. From this app's root: git submodule add -b release/3 <remote-url> vendor/submodules/vehicle_registry
              Until the gem is published, this app's Gemfile uses it from the submodule:
                gem "vehicle_registry", path: "vendor/submodules/vehicle_registry"
              Once published (bump lib/vehicle_registry/version.rb and push to release/3; the CI publishes it), switch to the published gem:
                4. Replace that line with gem "vehicle_registry", "~> <major.minor>"
                5. bundle update vehicle_registry --conservative, then commit Gemfile.lock together with the submodule pointer
              Its own tests run from its directory, on its own test database: cd <path-to-fleet_app>/vendor/submodules/vehicle_registry && bundle install && bin/rails db:create && bin/rails test
              From then on every change follows the same loop: edit and test in vendor/submodules/vehicle_registry, bump the version, push to release/3, wait for the gem server, bundle update vehicle_registry --conservative, commit Gemfile.lock + the submodule pointer.
     gemfile  vehicle_registry
```

The last line (`gemfile vehicle_registry`) is `add_gem_to_host_gemfile` appending
`gem "vehicle_registry", path: "vendor/submodules/vehicle_registry"` to `fleet_app`'s own
`Gemfile` — same end result as Step 3's own final step.

**Publishing to a private gem server.** By default the ATOM publishes to RubyGems.org. Pass
`--gem-host=gems.example.com` (just the host) to publish to a private gem server instead: the
gemspec's `allowed_push_host` becomes `https://gems.example.com`, the GitLab CI pushes there
(`GITLAB_GEM_REPO_TARGET`), and step 4 of the next steps says to declare the gem inside the app
Gemfile's `source "https://gems.example.com/" do ... end` block. "Create an ATOM" has no field
for this, so a VS Code-created ATOM always targets RubyGems.org until you change both values by
hand (see `CLAUDE.md` in the ATOM, "Publishing").

**Compared to Step 3's "Thecore 3: Create an ATOM"**: no difference — Step 3 delegates to this
exact generator (thecore_code_extension#40), so the resulting ATOM structure (see the file tree
above) is identical either way, including the `CLAUDE.md`, the `git init`'d commit, and the
dependency versions. The only real differences are how the inputs get collected — VS Code's
dialogs accept free text and convert spaces to `snake_case` for you, while this terminal
invocation needs an already-valid gem name typed directly — and `--gem-host`, which only the
terminal offers. Creating a remote and running the real `git submodule add` are still manual
steps either way; the generator only logs the exact commands for you to run.

Full reference: [GUIDE.md §4.2.1](GUIDE.md#421-the-thecoreatom-generator-terminal-alternative).

---

## Step 4 — Add a model to the ATOM

The vehicle registry needs a `Vehicle` model.

**Primary way — plain terminal**, from inside the ATOM:

```bash
cd vendor/submodules/vehicle_registry
bundle exec rails generate model Vehicle plate:string make:string model:string year:integer status:string
```

**Also available — VS Code extension:**

> **Right-click `vendor/submodules/vehicle_registry` in the Explorer → Thecore 3: Add a Model**

| Field | Format | Example value |
|---|---|---|
| Model name | PascalCase | `Vehicle` |
| Migration fields | `field:type` pairs, space-separated (leave empty to add fields later) | `plate:string make:string model:string year:integer status:string` |

Both paths run the exact same generator (`thecore_generators`' `Thecore::Generators::ModelGenerator`) and produce the same result — the extension delegates to it rather than reimplementing generation logic. `Thecore::Generators::WorkspaceContext` detects that the working directory (or an explicit `--atom=vehicle_registry`) is inside `vendor/submodules/vehicle_registry/`, so the model, migration, and test files land there directly — there is no separate "generate, then move" step any more:

1. Writes `vendor/submodules/vehicle_registry/db/migrate/..._create_vehicles.rb`
2. Writes `vendor/submodules/vehicle_registry/app/models/vehicle.rb`
3. Writes `vendor/submodules/vehicle_registry/test/models/vehicle_test.rb` — test generation is never suppressed

**Generated model file** (`vehicle_registry/app/models/vehicle.rb`):

```ruby
class Vehicle < ApplicationRecord
end
```

No `include` lines, and no concern files — `Vehicle` is already serialisable through the API and visible in the `rails_admin` sidebar, driven entirely by the default modules every `ApplicationRecord` subclass picks up automatically (see "Default-first models..." in [GUIDE.md §1](GUIDE.md#1-philosophy)). By default `smart_merge` with an empty hash — the default module's own baseline — exposes all non-sensitive fields, and the default admin navigation uses a generic label/icon.

**Customizing serialisation or admin UI.** The common case is realizing a model needs custom `json_attrs` or `rails_admin` configuration only *after* it already exists — add the concern by hand at that point rather than regenerating anything:

`vehicle_registry/app/models/concerns/api/vehicle.rb`:

```ruby
module Api::Vehicle
  extend ActiveSupport::Concern

  included do
    cattr_accessor :json_attrs
    self.json_attrs = ::ModelDrivenApi.smart_merge(json_attrs || {}, {
      only: [:id, :plate, :make, :model, :year, :status]
    })
  end
end
```

`vehicle_registry/app/models/concerns/rails_admin/vehicle.rb`:

```ruby
module RailsAdmin::Vehicle
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label I18n.t('admin.registries.label')
      navigation_icon 'fa fa-file'
    end
  end
end
```

...then `include Api::Vehicle` / `include RailsAdmin::Vehicle` in `vehicle.rb`. The `Vehicle` model is then visible in the `rails_admin` admin panel under the label defined by the i18n key — change the icon and label by editing this concern, no other file needs touching.

If the customization is already known at generation time instead, `--with-api-concern`/`--with-admin-concern` scaffold the same starter files and wire the `include` lines automatically:

```bash
bundle exec rails generate model Vehicle plate:string make:string model:string year:integer status:string \
  --with-api-concern --with-admin-concern
```

**Custom API actions.** Nothing is generated for these: add one by hand, only when a real
non-CRUD action is needed. `model_driven_api` dispatches a custom action to a method of the
model's `Endpoints::<Model>` class, a `NonCrudEndpoints` subclass. Declare that class once, empty,
where the model lives:

`vehicle_registry/app/models/endpoints/vehicle.rb`:

```ruby
class Endpoints::Vehicle < NonCrudEndpoints
end
```

Then add each action with `class_eval` inside `after_initialize`, in a dedicated initializer:

`vehicle_registry/config/initializers/vehicle_endpoints.rb`:

```ruby
Rails.application.config.after_initialize do
  Endpoints::Vehicle.class_eval do
    desc 'Vehicle', :archive, {
      patch: {
        summary: 'Archive a vehicle',
        operationId: 'archive',
        tags: ['Vehicle'],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'integer' } }
        ],
        responses: { 200 => { description: 'The archived vehicle' }, 403 => { description: 'Not allowed' } }
      }
    }

    def archive(params)
      vehicle = Vehicle.find(params[:id])
      # Custom actions skip model_driven_api's CanCan check: authorize the caller here.
      return [{ error: 'You are not authorized to access this page.' }, 403] unless
        Ability.new(User.find(params[:current_user_id])).can?(:update, vehicle)

      vehicle.update!(status: 'archived')
      [vehicle, 200]
    end
  end
end
```

It answers `PATCH /api/v2/vehicles/custom_action/archive/:id` and appears in the OpenAPI
document. Every action returns `[body, http_status]`. Use `class_eval`, never `include` of a
module: `model_driven_api` finds the actions with `instance_methods(false)`, which doesn't see
methods that come from an included module. The same `class_eval` adds an action to an
`Endpoints::` class another ATOM or gem already defines, from the main app or from your ATOM.

> **Introspection-based development in action:** the API response for `GET /api/vehicles` is built by `ModelDrivenApi` reading the model's `json_attrs` configuration at runtime — the default one if no `Api::Vehicle` concern exists, the overridden one if it does. You never write a serialiser class either way. Adding a new field to the migration and re-running `db:migrate` makes it appear in the API response automatically.

> **Wiring a `references` column.** None of `Vehicle`'s own fields are a reference, but if one had been — say a later model adds a `vehicle:references` column — the migration generator would also write the inverse `has_many :vehicles`/`has_one :vehicle` onto `Vehicle` automatically. See [GUIDE.md §4.4.1](GUIDE.md#441-inverse-association-wiring-any-context) for the full mechanism and generated file.

---

## Step 5 — Add a standalone migration to the ATOM

Sometimes you need to alter the schema without creating a new model — for example, to add an index or a column to an existing table.

**Primary way — plain terminal**, from inside the ATOM:

```bash
cd vendor/submodules/vehicle_registry
bundle exec rails generate migration AddMileageToVehicles mileage:integer
```

Or from anywhere, with `--atom=vehicle_registry`. The migration is written directly into `vendor/submodules/vehicle_registry/db/migrate/` — the same context detection as Step 4, no separate move step — and is ready to be run with `rails db:migrate` from the main app.

**Also available — VS Code extension:**

> **Right-click `vendor/submodules/vehicle_registry` in the Explorer → Thecore 3: Add a DB Migration**

| Field | Format | Example value |
|---|---|---|
| Migration name | PascalCase | `AddMileageToVehicles` |
| Migration fields | `field:type` pairs (optional) | `mileage:integer` |

The generated file follows the standard Rails migration format:

```ruby
class AddMileageToVehicles < ActiveRecord::Migration[7.2]
  def change
    add_column :vehicles, :mileage, :integer
  end
end
```

No further editing is required for simple additions. For complex migrations (custom SQL, data transforms) open the file and edit the `change` method directly.

If a field here had been a `references` column instead (e.g. `driver:references`), this same command would also wire the inverse association onto the referenced model — see [GUIDE.md §4.4.1](GUIDE.md#441-inverse-association-wiring-any-context) for the full mechanism.

---

## Step 6 — Add a root action (fleet dashboard)

A root action adds a section to the `rails_admin` main navigation sidebar. It is not tied to any model — it is a standalone page, ideal for dashboards, reports, or monitoring views.

> **Right-click `vendor/submodules/vehicle_registry` in the Explorer → Thecore 3: Add a Root Action**

| Field | Format | Example value |
|---|---|---|
| Action name | snake_case | `fleet_dashboard` |

The command generates:

```
vehicle_registry/
├── lib/root_actions/
│   └── fleet_dashboard.rb              ← RailsAdmin action definition
├── app/
│   ├── assets/
│   │   ├── javascripts/rails_admin/actions/
│   │   │   └── fleet_dashboard.js      ← ActionCable WebSocket client
│   │   └── stylesheets/rails_admin/actions/
│   │       └── fleet_dashboard.scss    ← scoped styles + loader animation
│   └── views/rails_admin/main/
│       └── fleet_dashboard.html.erb    ← ERB template
└── config/locales/
    ├── en.yml                          ← updated with "fleet_dashboard" key
    └── it.yml                          ← updated with "fleet_dashboard" key
```

**The action file** (`lib/root_actions/fleet_dashboard.rb`) registers the sidebar entry and its controller logic:

```ruby
RailsAdmin::Config::Actions.add_action "fleet_dashboard", :base, :root do
  link_icon 'fas fa-tachometer-alt'
  http_methods [:get, :post]
  controller do
    proc do
      # Populate @vehicles_count, @active_count, etc. here
      # They become available in the ERB template
    end
  end
end
```

The JavaScript file sets up a live ActionCable subscription so the dashboard can receive real-time updates without a page reload:

```javascript
document.addEventListener('DOMContentLoaded', () => {
  const consumer = ActionCable.createConsumer();
  consumer.subscriptions.create({ channel: 'FleetDashboardChannel' }, {
    received(data) {
      // Update dashboard widgets with data
    }
  });
});
```

The generator also takes care of registration for you — no manual step needed. It inserts a require line into `config/initializers/after_initialize.rb` inside the ATOM (creating the file from a skeleton first if it doesn't exist yet):

```ruby
Rails.application.configure do
  config.after_initialize do
    require 'root_actions/fleet_dashboard'
  end
end
```

...and a precompile line into `config/initializers/assets.rb` for the new action's assets:

```ruby
Rails.application.config.assets.precompile += %w( rails_admin/actions/fleet_dashboard.js rails_admin/actions/fleet_dashboard.css )
```

> **Why is the require its own explicit line, rather than an implicit autoload?**
> Thecore generates the action file but keeps its registration as one explicit line per action so you control load order. If you have ten root actions and only three are enabled in a given environment, you simply remove (or never generate) the require line for the others — Thecore never auto-discovers action files by scanning the directory. Re-running the generator for an action that already has its require line is safe: it's inserted idempotently, never duplicated.

---

## Step 7 — Add a member action (archive vehicle)

A member action adds a button or link to each row of a model's list in `rails_admin`. It operates on a specific record instance.

> **Right-click `vendor/submodules/vehicle_registry` in the Explorer → Thecore 3: Add a Member Action**

| Field | Format | Example value |
|---|---|---|
| Action name | snake_case | `archive_vehicle` |

The command generates the same file set as a root action, but the action definition uses `member` semantics:

```ruby
RailsAdmin::Config::Actions.add_action "archive_vehicle", :base, :member do
  link_icon 'fas fa-archive'
  http_methods [:get, :patch]
  # Show this button only on Vehicle records
  visible do
    bindings[:object].is_a?(::Vehicle)
  end
  controller do
    proc do
      if !request.xhr? && request.patch?
        # Perform the archive: set status to 'archived'
        @object.update!(status: 'archived')
        flash[:success] = I18n.t('admin.actions.archive_vehicle.success')
        redirect_to index_path(model_name: @abstract_model.to_param)
      elsif request.xhr? && request.get?
        # Return confirmation data to the client without a page reload
        render json: { vehicle: @object.plate, status: @object.status }
      end
    end
  end
end
```

The `visible` block ensures the button only appears on `Vehicle` rows. `bindings[:object]` is the current record — this is `rails_admin`'s introspection mechanism at work. You never specify which model or which ID; the framework resolves it.

The generator has already added the require line to `after_initialize.rb` for you — no manual step needed (see the callout at the end of Step 6 for why it's a separate explicit line per action):

```ruby
require 'member_actions/archive_vehicle'
```

---

## Step 8 — Check the ATOM's practices

`rails thecore:check_practices` audits an ATOM (or the main app) for the same Scaffold
Files/Models/Actions conventions the generators above produce, and can be run any time —
after hand-editing a generated file, after pulling someone else's branch, or just as a
habit before committing. It's a rake task, not a generator, so flags go after a literal
`--`.

To see it catch something, suppose the JS companion for the fleet dashboard from Step 6
got deleted by accident:

```bash
rm vendor/submodules/vehicle_registry/app/assets/javascripts/rails_admin/actions/fleet_dashboard.js
```

Run the audit scoped to that ATOM:

```bash
bundle exec rails thecore:check_practices -- --atom=vehicle_registry
```

```
vendor/submodules/vehicle_registry/app/assets/javascripts/rails_admin/actions/fleet_dashboard.js:
  [ERROR] fleet_dashboard: missing companion fleet_dashboard.js
```

> **Right-click `vendor/submodules/vehicle_registry` in the Explorer → Thecore 3: Check Practices** does the same thing from the VS Code extension, rendering the result as diagnostics instead of terminal output, with a QuickPick offering to re-run with `--fix` whenever a violation is fixable — like this one.

A missing companion file created by a generator (view/JS/SCSS) is always fixable: the audit
knows exactly which generator produced it and can re-run just that one template. Apply
every fixable violation in one pass with `--fix`:

```bash
bundle exec rails thecore:check_practices -- --atom=vehicle_registry --fix
```

```
✅ No violations found.
```

The fix delegated straight to `thecore:root_action`'s own template rendering — the
regenerated `fleet_dashboard.js` is byte-for-byte what Step 6 would have produced,
not a generic placeholder. `--fix` never asks its own confirmation: passing it means
you've already decided, whether that's you on the command line or the VS Code
extension after its own QuickPick.

Not every violation is fixable this way — a missing marker inside an existing,
possibly hand-customized file (rather than a missing file entirely) is reported but
left untouched, since regenerating over it could clobber real customization. `--json`
(`rails thecore:check_practices -- --json --atom=vehicle_registry`) emits the same
violations as structured data instead of text — what the VS Code extension and CI
actually consume — and the task exits non-zero whenever violations remain after any
`--fix` pass, so it's usable as a CI gate either way.

---

## Step 9 — Add a model directly to the main app

Not all models belong to a reusable ATOM. Configuration tables, app-specific join tables, or models that glue multiple ATOMs together belong in the main application.

**Primary way — plain terminal**, from the host app root:

```bash
bundle exec rails generate model FleetConfig key:string value:string
```

**Also available — VS Code extension:**

> **Right-click the project root folder (or `app/models/`) in the Explorer → Thecore 3: Add a Model**

| Field | Format | Example value |
|---|---|---|
| Model name | PascalCase | `FleetConfig` |
| Migration fields | `field:type` pairs | `key:string value:string` |

The behaviour is identical to adding a model inside an ATOM (Step 4), with one difference: no file needs redirecting anywhere — the model, migration, and test land directly in the host app's own `app/models`/`db/migrate`/`test`, since there is no ATOM context to detect. No `Api::`/`RailsAdmin::`/`Endpoints::` concern file is generated by default here either.

```
fleet_app/
├── db/migrate/
│   └── 20240315140000_create_fleet_configs.rb
├── app/models/
│   └── fleet_config.rb
└── test/models/
    └── fleet_config_test.rb
```

> **When to put a model in the main app vs. an ATOM?**
> Use the main app for models that exist only to configure or connect the application itself. Use an ATOM for any model that represents a feature domain that could, in principle, be reused in another Thecore project.

---

## Step 10 — Run the application

With the database seeded by `thecore:db:seed`, a default admin user was created. Start the Rails server:

```bash
rails s -p 3000 -b 0.0.0.0
```

Navigate to `http://localhost:3000/app` to access the `rails_admin` interface. Log in with the seeded admin credentials. You will see:

- The **Vehicle** model in the sidebar (under the default admin navigation label/icon — no `RailsAdmin::Vehicle` concern was needed to get here; add one, as shown in Step 4, only to customize it)
- The **Fleet Dashboard** root action in the main menu
- The **Archive Vehicle** button on each row of the Vehicle list

All of this is functional without writing any controller, route, serialiser, or policy file.

---

## Step 11 — The iteration cycle

From this point the development cycle for each new feature is:

```
1. Decide: does this feature belong in an existing ATOM, a new ATOM, or the main app?

2. If a new ATOM:
   Right-click root → Thecore 3: Create an ATOM

3. Add models:
   bundle exec rails generate model (from inside the ATOM, or the root)
   — or right-click ATOM (or root) → Thecore 3: Add a Model; both run the same generator
   → no Api::/RailsAdmin:: concern by default (--with-api-concern/--with-admin-concern to opt in)
   → a references field also wires the inverse association automatically (GUIDE.md §4.4.1)

4. Add standalone schema changes:
   bundle exec rails generate migration (from inside the ATOM)
   — or right-click ATOM → Thecore 3: Add a DB Migration → rails db:migrate

5. Add admin UI pages (dashboard-style):
   Right-click ATOM → Thecore 3: Add a Root Action (or rails generate thecore:root_action)
   → edit the controller proc
   → edit the ERB template
   (the require line in after_initialize.rb is added for you)

6. Add per-record admin UI buttons:
   Right-click ATOM → Thecore 3: Add a Member Action (or rails generate thecore:member_action)
   → edit the controller proc

   Add actions on a model's whole list the same way:
   Right-click ATOM → Thecore 3: Add a Collection Action (or rails generate thecore:collection_action)

7. Expose custom API endpoints:
   Declare the empty Endpoints::<Model> < NonCrudEndpoints class once (app/models/endpoints/<model>.rb)
   → add each action with class_eval in a config/initializers/ file's after_initialize block

8. Tune JSON output:
   Create (or open) concerns/api/<model>.rb
   → edit json_attrs with only:, except:, include:

9. Tune admin UI:
   Create (or open) concerns/rails_admin/<model>.rb
   → add list do, edit do, show do blocks
```

Each step is independent. You can add a root action without touching the model. You can extend the API without touching the admin config. Concerns exist only where a model actually customizes something, keeping each responsibility isolated without paying for boilerplate files nobody edits.

---

## Step 12 — Publish the ATOM and use the published gem

Until it is published, `fleet_app` uses `vehicle_registry` from its folder (`path:` in the
`Gemfile`). To share it, publish it as a gem and let the app use the published version, like every
other ATOM.

1. Create a repository for the ATOM, then follow the generator's next steps: `git remote add
   origin <url>`, `git push -u origin release/3`, and from `fleet_app`'s root
   `git submodule add -b release/3 <url> vendor/submodules/vehicle_registry`.
2. Bump `lib/vehicle_registry/version.rb` and push to `release/3`. The ATOM's CI publishes that
   version: on GitHub, `gempush.yml` (pushes to `release/3` only, the repository secret
   `RUBYGEMS_AUTH_TOKEN`) tags it and pushes it to RubyGems.org; on GitLab, `build_gem` runs only
   when `lib/*/version.rb` changes and pushes to `GITLAB_GEM_REPO_TARGET` (the `--gem-host`
   server, with the CI/CD variable `GEMS_REPO_CREDENTIALS`) or, when that isn't set, to
   RubyGems.org. A push that doesn't change the version publishes nothing.
3. Once the version is on the gem server, replace the `path:` line in `fleet_app`'s `Gemfile` with
   `gem "vehicle_registry", "~> 0.1"` (the version you published; `rails plugin new` starts at `0.1.0`), inside the `source "https://<server>/" do ... end` block
   for a private server, run `bundle update vehicle_registry --conservative`, and commit
   `Gemfile.lock` together with the submodule pointer.

From then on, every change to an ATOM follows the same loop, written in the app's `CLAUDE.md`
("Changing an ATOM"): edit and test in `vendor/submodules/<name>`, bump its version, push to
`release/3`, wait for the gem server, `bundle update <name> --conservative`, commit
`Gemfile.lock` with the submodule pointer. Never patch the installed gem, and never work around
an ATOM's bug from the app.

---

## Appendix A — Naming conventions

| What | Format | Example |
|---|---|---|
| Model name | PascalCase | `TcpConnection` |
| Migration name | PascalCase, descriptive | `AddTimeoutToConnections` |
| Root / member action name | snake_case | `fleet_dashboard` |
| ATOM name (input) | Free text | `Vehicle Registry` |
| ATOM name (generated) | snake_case | `vehicle_registry` |
| Migration fields | `field:type` pairs | `plate:string year:integer` |

## Appendix B — Available field types

Standard Rails migration types accepted by the Add Model and Add Migration commands:

| Type | Ruby/DB mapping |
|---|---|
| `string` | VARCHAR |
| `text` | TEXT |
| `integer` | INT |
| `bigint` | BIGINT |
| `float` | FLOAT |
| `decimal` | DECIMAL |
| `boolean` | BOOLEAN |
| `date` | DATE |
| `datetime` | DATETIME / TIMESTAMP |
| `references` | Foreign key + index; also wires the inverse `has_many`/`has_one` on the target model (see GUIDE.md §4.4.1) |
| `json` / `jsonb` | JSON column (PostgreSQL) |

## Appendix C — What each concern file controls

None of these files exists by default any more — see [GUIDE.md §1](GUIDE.md#1-philosophy). Create the ones a given model needs (by hand, or via `--with-api-concern`/`--with-admin-concern` at generation time for the first two); the table below is what each controls once it exists.

| File | Controls | How to customise |
|---|---|---|
| `concerns/api/<model>.rb` | JSON fields in API responses | Edit `json_attrs`: use `only:`, `except:`, `methods:`, `include:` |
| `concerns/rails_admin/<model>.rb` | Admin sidebar label, icon, list/edit/show fields | Add `list do`, `edit do`, `show do` blocks inside `rails_admin do` |
| `app/models/endpoints/<model>.rb` + an initializer | Custom non-CRUD REST actions | Declare the empty `Endpoints::<Model> < NonCrudEndpoints` class, then add each action (OpenAPI `desc` + method) with `class_eval` inside `after_initialize` (see Step 4) |
