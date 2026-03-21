# Building a Thecore Application from Scratch

A step-by-step walkthrough for creating a complete Thecore application, from an empty folder to a running Rails API with a modular engine.

---

## Before you begin: the Thecore mindset

Thecore is designed around five principles that shape every decision in this walkthrough. Understanding them upfront makes every generated file and folder feel obvious rather than arbitrary.

### Convention over configuration

Every filename, folder, module namespace, and class name follows a predictable pattern. You will never choose where to put a model concern, a migration, or an admin action: Thecore generates it in the right place, with the right name, automatically. This consistency means that any developer familiar with Thecore can open any Thecore project and immediately navigate it without a README.

### High automation

No boilerplate is written by hand. A single VS Code context menu action triggers a chain of `rails g`, `bundle install`, file moves, YAML merges, and concern scaffolding. The goal is that a feature domain — model, admin UI, API serialisation, custom endpoints — is ready to be filled with business logic within seconds of clicking a menu entry.

### High standardisation

Every ATOM (modular engine) has the same internal layout. Every model has the same three concern files. Every root action has the same file structure. This makes the codebase predictable at scale: adding a tenth ATOM feels identical to adding the first one.

### Introspection-based development

Thecore generates code that configures itself by reading the model structure at runtime. The `Api::ModelName` concern uses `ModelDrivenApi.smart_merge` to compose the JSON serialisation configuration; `RailsAdmin::ModelName` uses `rails_admin do` blocks that are loaded dynamically. You add a field to a migration and it appears in the API and admin UI without touching configuration files.

### Sensible defaults

Everything generated is immediately functional. A new model is visible in the admin UI, serialised in the API, and has a stub for custom endpoints — all before you write a single line of business logic. Defaults are designed to be correct for the common case and easy to override for the specific case.

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
- The **Thecore** VS Code extension installed (search `gabrieletassoni.thecore` in the Extensions panel)

---

## Step 1 — Open the devcontainer

Create an empty folder called `fleet_app` and open it in VS Code.

```
File → Open Folder → select fleet_app
```

VS Code will ask if you want to reopen in a container. If the folder does not already have a `.devcontainer/` directory, generate it first:

> **Right-click the `fleet_app` folder in the Explorer → Thecore 3: Setup Devcontainer**

VS Code generates:

```
fleet_app/
└── .devcontainer/
    ├── devcontainer.json
    ├── docker-compose.yml
    └── Dockerfile
```

Then reopen in the container:

```
Ctrl+Shift+P → Dev Containers: Reopen in Container
```

The container starts with Ruby, Rails, Node.js, Docker-in-Docker, and all Thecore tooling already installed. Your terminal is now running inside the container.

> **Why a devcontainer?**
> Every developer on the team runs the same binary versions of Ruby, Rails, bundler, Node, and the database driver. There is no "works on my machine" problem. The devcontainer image is rebuilt weekly and published to Docker Hub, so it always tracks the latest Thecore-compatible toolchain.

---

## Step 2 — Create the main application

> **Right-click the `fleet_app` root folder in the Explorer → Thecore 3: Create an App**

Watch the **Thecore: Create App** output channel. The command runs the following sequence automatically:

| Step | What happens |
|---|---|
| Pre-flight checks | Verifies `ruby`, `rails`, `bundle` are available and the workspace is empty |
| `rails new .` | Bootstraps a Rails app with PostgreSQL and Sprockets |
| `.gitignore` | Overwrites the default Rails gitignore with a comprehensive Thecore-specific one |
| `git init` | Initialises the repository with a `main` branch and makes the initial commit |
| Gemfile additions | Appends `sassc-rails`, `rails-erd`, `rails_admin`, `devise`, `cancancan` |
| `bundle install` | Installs all gems |
| Rails generators | Runs `devise:install`, `rails_admin:install`, `active_storage:install`, `action_text:install`, `action_mailbox:install`, `cancan:ability`, `erd:install` |
| Thecore gems | Appends `model_driven_api ~> 3.1` and `thecore_ui_rails_admin ~> 3.2` and runs `bundle install` again |
| CI/CD | Creates `.gitlab-ci.yml` with build, delivery (to-dev), and deploy (to-prod) stages |
| Sidekiq | Creates `config/sidekiq.yml` with dynamic queue configuration |
| Version file | Creates `version` containing `3.0.1` |
| Database | Runs `db:create`, `db:migrate`, `thecore:db:seed` |
| Vendor directories | Creates `vendor/custombuilds/`, `vendor/deploytargets/`, `vendor/submodules/` |
| Final commit | Commits everything with `git` |

When the output channel shows `✅ Thecore 3 App created successfully.` the application is fully wired and the database is seeded with the default Thecore admin user.

**What you now have:**

```
fleet_app/
├── app/
│   ├── models/
│   │   └── concerns/            ← app-level concerns (empty for now)
│   └── ...
├── config/
│   ├── sidekiq.yml              ← Sidekiq queue configuration
│   └── ...
├── db/
├── vendor/
│   ├── custombuilds/            ← custom Dockerfiles per deploy target
│   ├── deploytargets/           ← per-customer .env files
│   └── submodules/              ← ATOMs will live here
├── .gitlab-ci.yml               ← CI/CD pipeline, ready to use
└── version                      ← semantic version seed
```

> **Sensible defaults in action:** the admin UI (`rails_admin`), authentication (`devise`), authorisation (`cancancan`), background jobs (`sidekiq`), and REST API (`model_driven_api`) are all configured and functional before you write a single line of business logic.

> **Note on `raise_on_missing_callback_actions`:** the command automatically sets this to `false` in `config/environments/development.rb`. This prevents Rails from raising errors on before/after action callbacks that are handled by Thecore's engine, which is the correct default for Thecore development.

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

The command:

1. Runs `rails plugin new vendor/submodules/vehicle_registry -fG --full --skip-gemfile-entry`
2. Rewrites the gemspec with your inputs and sets the dependencies to `model_driven_api ~> 3.1` and `thecore_ui_rails_admin ~> 3.2`
3. Creates the full Thecore ATOM folder structure
4. Adds `gem "vehicle_registry", path: "vendor/submodules/vehicle_registry"` to the main app `Gemfile`

**What is generated inside the ATOM:**

```
vendor/submodules/vehicle_registry/
├── vehicle_registry.gemspec           ← gem metadata (author, deps, version)
├── app/
│   ├── models/
│   │   └── concerns/
│   │       ├── api/                   ← Api:: concerns go here
│   │       └── rails_admin/           ← RailsAdmin:: concerns go here
│   ├── assets/
│   │   ├── javascripts/rails_admin/actions/
│   │   └── stylesheets/rails_admin/actions/
│   └── views/rails_admin/main/        ← action templates go here
├── config/
│   ├── initializers/
│   │   ├── after_initialize.rb        ← hook to require root/member actions
│   │   ├── add_to_db_migration.rb     ← registers db/migrate with Rails
│   │   ├── assets.rb                  ← asset precompile declarations
│   │   └── abilities.rb               ← CanCan ability class stub
│   └── locales/
│       ├── en.yml                     ← English i18n stubs
│       └── it.yml                     ← Italian i18n stubs
├── db/
│   ├── migrate/                       ← ATOM migrations (moved here automatically)
│   └── seeds.rb                       ← ATOM seed data
└── lib/
    ├── root_actions/                  ← rails_admin main menu sections
    ├── member_actions/                ← rails_admin per-row buttons
    └── collection_actions/            ← rails_admin collection-level actions
```

> **Why are migrations inside the ATOM?**
> The `add_to_db_migration.rb` initialiser adds the ATOM's `db/migrate/` path to Rails' migration lookup. This means `rails db:migrate` in the main app finds and runs all ATOM migrations automatically. Keeping them inside the ATOM makes the domain self-contained: you can add this ATOM to another project and its schema comes with it.

> **Convention in action:** note that you never chose any of these paths or filenames. The name `Vehicle Registry` became `vehicle_registry` everywhere — folder name, gemspec name, Gemfile entry, module namespace — without any additional input.

---

## Step 4 — Add a model to the ATOM

The vehicle registry needs a `Vehicle` model.

> **Right-click `vendor/submodules/vehicle_registry` in the Explorer → Thecore 3: Add a Model**

| Field | Format | Example value |
|---|---|---|
| Model name | PascalCase | `Vehicle` |
| Migration fields | `field:type` pairs, space-separated (leave empty to add fields later) | `plate:string make:string model:string year:integer status:string` |

The command:

1. Runs `rails g model Vehicle plate:string make:string model:string year:integer status:string --skip-test-framework` from the app root
2. Moves `db/migrate/..._create_vehicles.rb` → `vendor/submodules/vehicle_registry/db/migrate/`
3. Moves `app/models/vehicle.rb` → `vendor/submodules/vehicle_registry/app/models/`
4. Creates three concern files inside the ATOM
5. Injects concern includes into the model class

**Generated model file** (`vehicle_registry/app/models/vehicle.rb`):

```ruby
class Vehicle < ApplicationRecord
  include Api::Vehicle
  include RailsAdmin::Vehicle
end
```

**Generated API concern** (`vehicle_registry/app/models/concerns/api/vehicle.rb`):

```ruby
module Api::Vehicle
  extend ActiveSupport::Concern

  included do
    cattr_accessor :json_attrs
    self.json_attrs = ::ModelDrivenApi.smart_merge (json_attrs || {}), {}
  end
end
```

By default, `smart_merge` with an empty hash exposes all non-sensitive fields. To restrict the output, edit the concern:

```ruby
self.json_attrs = ::ModelDrivenApi.smart_merge (json_attrs || {}), {
  only: [:id, :plate, :make, :model, :year, :status]
}
```

**Generated admin concern** (`vehicle_registry/app/models/concerns/rails_admin/vehicle.rb`):

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

The `Vehicle` model is now immediately visible in the `rails_admin` admin panel under the label defined by the i18n key. Change the icon and label by editing this concern — no other file needs touching.

**Generated endpoints concern** (`vehicle_registry/app/models/concerns/endpoints/vehicle.rb`):

```ruby
class Endpoints::Vehicle < NonCrudEndpoints
  # Custom non-CRUD API actions go here.
  # Uncomment the template below to add one.
  #
  # self.desc 'Vehicle', :archive, {
  #   patch: {
  #     summary:     "Archive a vehicle",
  #     operationId: "archive",
  #     tags:        ["Vehicle"],
  #     ...
  #   }
  # }
  # def archive(params)
  #   { archived: true }, 200
  # end
end
```

> **Introspection-based development in action:** the API response for `GET /api/vehicles` is built by `ModelDrivenApi` reading the model's `json_attrs` configuration at runtime. You never write a serialiser class. Adding a new field to the migration and re-running `db:migrate` makes it appear in the API response automatically, because the default configuration exposes all fields.

---

## Step 5 — Add a standalone migration to the ATOM

Sometimes you need to alter the schema without creating a new model — for example, to add an index or a column to an existing table.

> **Right-click `vendor/submodules/vehicle_registry` in the Explorer → Thecore 3: Add a DB Migration**

| Field | Format | Example value |
|---|---|---|
| Migration name | PascalCase | `AddMileageToVehicles` |
| Migration fields | `field:type` pairs (optional) | `mileage:integer` |

The command runs `rails g migration AddMileageToVehicles mileage:integer` and moves the resulting file from `db/migrate/` in the app root to `vendor/submodules/vehicle_registry/db/migrate/`. The migration is ready to be run with `rails db:migrate` from the main app.

The generated file follows the standard Rails migration format:

```ruby
class AddMileageToVehicles < ActiveRecord::Migration[7.2]
  def change
    add_column :vehicles, :mileage, :integer
  end
end
```

No further editing is required for simple additions. For complex migrations (custom SQL, data transforms) open the file and edit the `change` method directly.

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

**Important:** after generating the action, open `config/initializers/after_initialize.rb` inside the ATOM and add the require line:

```ruby
Rails.application.configure do
  config.after_initialize do
    require 'root_actions/fleet_dashboard'
  end
end
```

Also open `config/initializers/assets.rb` and uncomment the precompile lines for the new action's assets:

```ruby
Rails.application.config.assets.precompile += %w(
  main_fleet_dashboard.js
  main_fleet_dashboard.css
)
```

> **Why is the require manual?**
> Thecore generates the action file but leaves its registration explicit so you control load order. If you have ten root actions and only three are enabled in a given environment, you simply don't require the others in `after_initialize.rb`.

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

Add the require to `after_initialize.rb`:

```ruby
require 'member_actions/archive_vehicle'
```

---

## Step 8 — Add a model directly to the main app

Not all models belong to a reusable ATOM. Configuration tables, app-specific join tables, or models that glue multiple ATOMs together belong in the main application.

> **Right-click the project root folder (or `app/models/`) in the Explorer → Thecore 3: Add a Model**

| Field | Format | Example value |
|---|---|---|
| Model name | PascalCase | `FleetConfig` |
| Migration fields | `field:type` pairs | `key:string value:string` |

The behaviour is identical to adding a model inside an ATOM, with one difference: **no file is moved**. Rails generates the migration in `db/migrate/` and the model in `app/models/`, and they stay there. The three concern files are created in `app/models/concerns/`.

```
fleet_app/
├── db/migrate/
│   └── 20240315140000_create_fleet_configs.rb
└── app/models/
    ├── fleet_config.rb
    └── concerns/
        ├── api/fleet_config.rb
        ├── rails_admin/fleet_config.rb
        └── endpoints/fleet_config.rb
```

> **When to put a model in the main app vs. an ATOM?**
> Use the main app for models that exist only to configure or connect the application itself. Use an ATOM for any model that represents a feature domain that could, in principle, be reused in another Thecore project.

---

## Step 9 — Run the application

With the database seeded by `thecore:db:seed`, a default admin user was created. Start the Rails server:

```bash
rails s -p 3000 -b 0.0.0.0
```

Navigate to `http://localhost:3000/app` to access the `rails_admin` interface. Log in with the seeded admin credentials. You will see:

- The **Vehicle** model in the sidebar (under the navigation label defined in `RailsAdmin::Vehicle`)
- The **Fleet Dashboard** root action in the main menu
- The **Archive Vehicle** button on each row of the Vehicle list

All of this is functional without writing any controller, route, serialiser, or policy file.

---

## Step 10 — The iteration cycle

From this point the development cycle for each new feature is:

```
1. Decide: does this feature belong in an existing ATOM, a new ATOM, or the main app?

2. If a new ATOM:
   Right-click root → Thecore 3: Create an ATOM

3. Add models:
   Right-click ATOM (or root) → Thecore 3: Add a Model

4. Add standalone schema changes:
   Right-click ATOM → Thecore 3: Add a DB Migration → rails db:migrate

5. Add admin UI pages (dashboard-style):
   Right-click ATOM → Thecore 3: Add a Root Action
   → edit the controller proc
   → edit the ERB template
   → add require to after_initialize.rb

6. Add per-record admin UI buttons:
   Right-click ATOM → Thecore 3: Add a Member Action
   → edit the controller proc
   → add require to after_initialize.rb

7. Expose custom API endpoints:
   Open concerns/endpoints/<model>.rb
   → uncomment and complete the endpoint template

8. Tune JSON output:
   Open concerns/api/<model>.rb
   → edit json_attrs with only:, except:, include:

9. Tune admin UI:
   Open concerns/rails_admin/<model>.rb
   → add list do, edit do, show do blocks
```

Each step is independent. You can add a root action without touching the model. You can extend the API without touching the admin config. The concerns keep each responsibility isolated.

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
| `references` | Foreign key + index |
| `json` / `jsonb` | JSON column (PostgreSQL) |

## Appendix C — What each concern file controls

| File | Controls | How to customise |
|---|---|---|
| `concerns/api/<model>.rb` | JSON fields in API responses | Edit `json_attrs`: use `only:`, `except:`, `methods:`, `include:` |
| `concerns/rails_admin/<model>.rb` | Admin sidebar label, icon, list/edit/show fields | Add `list do`, `edit do`, `show do` blocks inside `rails_admin do` |
| `concerns/endpoints/<model>.rb` | Custom non-CRUD REST actions | Uncomment the template, fill in the OpenAPI descriptor and the method body |
