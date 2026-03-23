# Thecore Developer Guide

## Table of Contents

1. [Philosophy](#1-philosophy)
2. [Development environment](#2-development-environment)
3. [Application lifecycle](#3-application-lifecycle)
   - 3.1 [Setup the devcontainer](#31-setup-the-devcontainer)
   - 3.2 [Create the main application](#32-create-the-main-application)
   - 3.3 [Add models to the main application](#33-add-models-to-the-main-application)
4. [ATOM lifecycle](#4-atom-lifecycle)
   - 4.1 [What is an ATOM](#41-what-is-an-atom)
   - 4.2 [Create an ATOM](#42-create-an-atom)
   - 4.3 [Add a database migration](#43-add-a-database-migration)
   - 4.4 [Add a model to an ATOM](#44-add-a-model-to-an-atom)
   - 4.5 [Extend a model from another ATOM](#45-extend-a-model-from-another-atom)
   - 4.6 [Add a root action](#46-add-a-root-action)
   - 4.7 [Add a member action](#47-add-a-member-action)
5. [Model anatomy](#5-model-anatomy)
6. [Deploy](#6-deploy)
7. [Command reference](#7-command-reference)

---

## 1. Philosophy

Thecore is a Ruby on Rails framework built around three guiding principles.

### Convention over configuration

Every generated file follows a strict naming and folder convention. This uniformity means a developer joining an existing Thecore project immediately knows where every piece of logic lives, without reading documentation or asking questions.

### Modular architecture via ATOMs

A Thecore application is not a monolith. The main Rails application is intentionally kept thin: it bootstraps the framework and wires together a set of **ATOMs** (Architectural Task-Oriented Modules). Each ATOM is a self-contained Rails engine packaged as a Ruby gem and included in the main app as a Git submodule under `vendor/submodules/`. This gives you:

- **Independent versioning and release** of each feature domain.
- **Reuse across projects**: an ATOM developed for one customer can be included in another project with a single `git submodule add`.
- **Clean separation of concerns** at the repository level, not just at the class level.

### Fat model via concerns

Instead of scattering logic across controllers, serialisers, policy objects, and admin configurators, Thecore concentrates all model behaviour in dedicated concern files grouped by responsibility:

| Concern | Responsibility |
|---|---|
| `Api::ModelName` | JSON serialisation for the REST API |
| `RailsAdmin::ModelName` | Admin UI configuration (`rails_admin`) |
| `Endpoints::ModelName` | Custom non-CRUD API actions (OpenAPI-documented) |

This makes models introspectable, composable, and straightforward to extend without touching the core model file.

---

## 2. Development environment

### Prerequisites

| Tool | Purpose |
|---|---|
| Docker | Runs the devcontainer |
| VS Code | IDE |
| [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) | Opens the project inside the container |
| Thecore extension — [open-vsx.org](https://open-vsx.org/extension/gabrieletassoni/thecore) (recommended) or [GitHub Releases](https://github.com/gabrieletassoni/vscode-thecore/releases) | Provides all Thecore commands |

For platform-specific installation instructions see:
- [Linux (Ubuntu 24.04)](SETUP_VSCODE_LINUX.md)
- [Windows 11 via WSL](SETUP_VSCODE_WINDOWS.md)
- [macOS](SETUP_VSCODE_MACOS.md)

### What the devcontainer contains

Opening this repository in VS Code and selecting **Reopen in Container** builds an image from `.devcontainer/Dockerfile` based on `mcr.microsoft.com/vscode/devcontainers/base:bookworm`. The image includes:

- Ruby, Rubocop, ruby-lsp, thor
- Node.js 20, npm, yarn
- `yo`, `generator-code`, `@vscode/vsce`, `esbuild`, `rimraf` (for building VS Code extensions)
- Docker-in-Docker (the host Docker socket is bind-mounted, so you can build and run containers from inside the devcontainer)

The VS Code extensions pre-installed in the devcontainer are:

- `ms-azuretools.vscode-docker`
- `misogi.ruby-rubocop`
- `rogalmic.bash-debug`
- `timonwong.shellcheck`
- `eamodio.gitlens`
- `github.vscode-github-actions`
- `Anthropic.claude-code`

> The Thecore extension itself is packaged by `bin/build-for-dev` and copied into the image at `/etc/thecore/thecore.vsix` during the Docker image build, so it is always available and versioned together with the devcontainer.

### Opening the devcontainer

```
1. Clone this repository (including submodules):
   git clone --recurse-submodules <repo-url>

2. Open the folder in VS Code.

3. When prompted "Reopen in Container", accept.
   Alternatively: Ctrl+Shift+P → "Dev Containers: Reopen in Container"
```

Once inside the container your terminal is ready with all tools available.

---

## 3. Application lifecycle

All Thecore commands are accessed by **right-clicking on a folder in the VS Code Explorer panel** and selecting the relevant entry from the context menu, or from the Command Palette (`Ctrl+Shift+P` / `Cmd+Shift+P`).

The menu entries shown depend on where you right-click:

| Location | Commands shown |
|---|---|
| Any folder **outside** `vendor/submodules/` | Setup Devcontainer, Create an App, Create an ATOM, Add a Model |
| A folder **directly inside** `vendor/submodules/` | Add a Model, Add a DB Migration, Add a Root Action, Add a Member Action |

---

### 3.1 Setup the devcontainer

**Command:** `Thecore 3: Setup Devcontainer`

**When to use:** before creating the application, when you need to add devcontainer support to an existing empty workspace.

**What it generates:**

```
.devcontainer/
  devcontainer.json       ← VS Code devcontainer config
  docker-compose.yml      ← service definition for the devcontainer
  Dockerfile              ← devcontainer image definition
```

**Example workflow:**

```
1. Create an empty folder and open it in VS Code.
2. Right-click the root folder in the Explorer.
3. Select "Thecore 3: Setup Devcontainer".
4. Reopen the folder in the container when prompted.
```

---

### 3.2 Create the main application

**Command:** `Thecore 3: Create an App`

**When to use:** once, at the beginning of a project, inside the devcontainer.

**Pre-conditions:**
- A workspace is open.
- `ruby`, `rails`, and `bundle` are available in the shell.

**What it does (in order):**

1. Runs `rails new . --database=postgresql`.
2. Adds the core Thecore gems to the `Gemfile`:
   - `rails_admin`, `devise`, `cancancan`
   - `model_driven_api ~> 3.1`
   - `thecore_ui_rails_admin ~> 3.2`
   - `sassc-rails`
   - `rails-erd` (development group)
3. Runs `bundle install`.
4. Runs the standard generators: `devise:install`, `rails_admin:install`, `cancan:ability`, `erd:install`, `active_storage:install`, `action_text:install`, `action_mailbox:install`.
5. Creates configuration files: `.gitlab-ci.yml`, `config/sidekiq.yml`, `version`.
6. Creates the vendor directory structure:
   ```
   vendor/
     custombuilds/       ← custom Dockerfiles per deploy target
     deploytargets/      ← per-customer .env files and host references
     submodules/         ← Git submodules (ATOMs live here)
   ```
7. Runs `rails db:migrate` and `rails db:seed`.

**Resulting project structure (highlights):**

```
my_app/
├── app/
│   ├── models/
│   │   └── concerns/         ← app-level model concerns
│   └── ...
├── config/
│   ├── sidekiq.yml
│   └── ...
├── db/
├── vendor/
│   ├── custombuilds/
│   ├── deploytargets/
│   └── submodules/           ← ATOMs will be added here
├── .gitlab-ci.yml
└── version
```

**Example workflow:**

```
1. Open the project folder in the devcontainer.
2. Right-click the root folder in the Explorer.
3. Select "Thecore 3: Create an App".
4. Wait for the Output panel ("Thecore: Create App") to show completion.
5. Verify the database is reachable (the DATABASE_URL env var must be set).
```

---

### 3.3 Add models to the main application

**Command:** `Thecore 3: Add a Model` (in the main app context)

**When to use:** when the model logically belongs to the main application rather than to a reusable ATOM.

**How to invoke:** right-click on **any folder outside** `vendor/submodules/` (e.g. the project root or `app/models/`) and select "Thecore 3: Add a Model".

**Inputs requested:**

| Input | Format | Example |
|---|---|---|
| Model name | PascalCase | `CustomerOrder` |
| Migration fields | `field:type` pairs, space-separated | `total:decimal status:string` |

**What it generates:**

```
db/
  migrate/
    20240315120000_create_customer_orders.rb   ← standard Rails migration

app/
  models/
    customer_order.rb                          ← model with concern includes
    concerns/
      api/
        customer_order.rb                      ← Api::CustomerOrder
      rails_admin/
        customer_order.rb                      ← RailsAdmin::CustomerOrder
      endpoints/
        customer_order.rb                      ← Endpoints::CustomerOrder
```

The model file is automatically updated to include the concerns:

```ruby
class CustomerOrder < ApplicationRecord
  include Api::CustomerOrder
  include RailsAdmin::CustomerOrder
end
```

> See [Model anatomy](#5-model-anatomy) for the full content of each concern file.

---

## 4. ATOM lifecycle

### 4.1 What is an ATOM

An ATOM is a **Rails engine** packaged as a Ruby gem. It encapsulates a self-contained feature domain: its own models, migrations, controllers, views, admin UI configuration, and API endpoints. It lives under `vendor/submodules/` as a Git submodule.

```
vendor/
  submodules/
    my_atom/                 ← one ATOM
      my_atom.gemspec
      app/
        models/
          concerns/
      db/
        migrate/
      lib/
        root_actions/
        member_actions/
      config/
        locales/
```

The main application's `Gemfile` references ATOMs via their local path:

```ruby
gem 'my_atom', path: 'vendor/submodules/my_atom'
```

This means ATOMs are developed in-place alongside the application and committed independently to their own Git repository.

---

### 4.2 Create an ATOM

**Command:** `Thecore 3: Create an ATOM`

**When to use:** when you need a new self-contained feature domain.

**How to invoke:** right-click on **any folder outside** `vendor/submodules/` and select "Thecore 3: Create an ATOM".

**Inputs requested:**

| Input | Format | Example |
|---|---|---|
| ATOM name | Free text (converted to snake_case) | `TCP Debugger` → `tcp_debugger` |
| Summary | Short description | `Monitors TCP connections` |
| Description | Full description | `Provides real-time TCP debugging...` |
| Author | Full name | `Gabriele Tassoni` |
| Email | Valid email | `gabriele@example.com` |
| URL | Valid URL | `https://github.com/acme/tcp_debugger` |

**What it does:**

1. Runs `rails plugin new vendor/submodules/tcp_debugger -fG --full --skip-gemfile-entry`.
2. Creates the full ATOM directory structure:

```
vendor/submodules/tcp_debugger/
├── tcp_debugger.gemspec
├── app/
│   ├── models/
│   │   └── concerns/
│   │       ├── api/
│   │       └── rails_admin/
│   ├── assets/
│   │   ├── javascripts/rails_admin/actions/
│   │   └── stylesheets/rails_admin/actions/
│   └── views/rails_admin/main/
├── config/
│   ├── initializers/
│   │   ├── after_initialize.rb
│   │   ├── add_to_db_migration.rb
│   │   ├── assets.rb
│   │   └── abilities.rb
│   └── locales/
│       ├── en.yml
│       └── it.yml
├── db/
│   └── migrate/
└── lib/
    ├── root_actions/
    ├── member_actions/
    └── collection_actions/
```

3. Adds CI/CD pipelines:
   - `.gitlab-ci.yml` for GitLab
   - `.github/workflows/gempush.yml` for GitHub Actions (publishes the gem on tag push)
4. Adds the ATOM to the main application's `Gemfile`:
   ```ruby
   gem 'tcp_debugger', path: 'vendor/submodules/tcp_debugger'
   ```
5. Runs `bundle install`.

**Gemspec dependencies:**

An ATOM can depend on either or both base Thecore ATOMs:

```ruby
# For ATOMs that need the admin UI:
s.add_dependency 'thecore_ui_rails_admin', '~> 3.0'
# For ATOMs that need the REST API:
s.add_dependency 'model_driven_api', '~> 3.0'
```

If your ATOM depends on another ATOM that already pulls in `thecore_ui_rails_admin` or `model_driven_api`, you only need to declare the other ATOM as a dependency.

**Autoloading dependencies:**

For every gem declared in the `.gemspec`, add the matching `require` to `lib/[atom_name].rb`:

```ruby
# lib/tcp_debugger.rb
require 'thecore_ui_rails_admin'
require 'model_driven_api'
require 'tcp_debugger/engine'
```

**Versioning:**

Keep the ATOM gem's major version aligned with the Thecore major version it targets (e.g. `3.x.x` for Thecore 3 applications). The main application's version file (`version`) follows the same scheme: `<major>.<year>.<month>.<day>`.

**Example workflow:**

```
1. Right-click the project root in the Explorer.
2. Select "Thecore 3: Create an ATOM".
3. Fill in the requested fields.
4. Watch the Output panel for completion.
5. The new ATOM is immediately available to the main app.
```

---

### 4.3 Add a database migration

**Command:** `Thecore 3: Add a DB Migration`

**When to use:** when you need to alter the database schema from within an ATOM (add a table, add a column, etc.) without generating a full model.

**How to invoke:** right-click on the **ATOM root folder** inside `vendor/submodules/` (e.g. `vendor/submodules/tcp_debugger`) and select "Thecore 3: Add a DB Migration".

**Inputs requested:**

| Input | Format | Example |
|---|---|---|
| Migration name | PascalCase | `AddTimeoutToConnections` |
| Migration fields | `field:type` pairs (optional) | `timeout:integer retries:integer` |

**What it does:**

1. Runs `rails g migration AddTimeoutToConnections timeout:integer retries:integer` from the Rails app root.
2. Moves the generated file from `db/migrate/` in the app root into the ATOM's own `db/migrate/` directory.

```
vendor/submodules/tcp_debugger/
  db/
    migrate/
      20240315130000_add_timeout_to_connections.rb   ← moved here
```

> Keeping migrations inside the ATOM ensures the feature domain is fully self-contained and portable.

---

### 4.4 Add a model to an ATOM

**Command:** `Thecore 3: Add a Model` (in the ATOM context)

**How to invoke:** right-click on the **ATOM root folder** inside `vendor/submodules/` and select "Thecore 3: Add a Model".

**Inputs requested:**

| Input | Format | Example |
|---|---|---|
| Model name | PascalCase | `TcpConnection` |
| Migration fields | `field:type` pairs (optional) | `host:string port:integer status:string` |

**What it does:**

1. Runs `rails g model TcpConnection host:string port:integer status:string --skip-test-framework` from the app root.
2. Moves the migration to `vendor/submodules/tcp_debugger/db/migrate/`.
3. Moves the model to `vendor/submodules/tcp_debugger/app/models/`.
4. Creates the three concern files inside the ATOM:

```
vendor/submodules/tcp_debugger/
  app/
    models/
      tcp_connection.rb                      ← includes concerns
      concerns/
        api/
          tcp_connection.rb                  ← Api::TcpConnection
        rails_admin/
          tcp_connection.rb                  ← RailsAdmin::TcpConnection
        endpoints/
          tcp_connection.rb                  ← Endpoints::TcpConnection
```

5. Injects the concern includes into the model:

```ruby
class TcpConnection < ApplicationRecord
  include Api::TcpConnection
  include RailsAdmin::TcpConnection
end
```

---

### 4.5 Extend a model from another ATOM

When you need to add behaviour (validations, associations, callbacks, admin UI configuration) to a model that is defined in a **different** ATOM or gem, do not modify that gem directly. Instead:

1. Create a concern file in `config/initializers/` of the consuming ATOM, named `concern_[model_name].rb`:

```ruby
# config/initializers/concern_tcp_connection.rb
module ConcernTcpDebuggerTcpConnection
  extend ActiveSupport::Concern

  included do
    validates :host, presence: true
    # additional behaviour here
  end
end
```

2. In `config/initializers/after_initialize.rb`, include the concern into the target model after Rails initialises:

```ruby
Rails.application.configure do
  config.after_initialize do
    TcpConnection.send(:include, ConcernTcpDebuggerTcpConnection)
  end
end
```

This pattern keeps each ATOM self-contained while allowing cross-ATOM composition.

---

### 4.6 Add a root action

**Command:** `Thecore 3: Add a Root Action`

**When to use:** when you need a new section in the `rails_admin` main navigation menu — typically a dashboard view, a monitoring panel, or any page not directly tied to a specific model row.

**How to invoke:** right-click on the **ATOM root folder** inside `vendor/submodules/` and select "Thecore 3: Add a Root Action".

**Inputs requested:**

| Input | Format | Example |
|---|---|---|
| Action name | snake_case | `connection_dashboard` |

**What it generates:**

```
vendor/submodules/tcp_debugger/
  lib/
    root_actions/
      connection_dashboard.rb          ← RailsAdmin action definition
  app/
    assets/
      javascripts/rails_admin/actions/
        connection_dashboard.js        ← ActionCable WebSocket client
      stylesheets/rails_admin/actions/
        connection_dashboard.scss      ← styles with loader animation
    views/rails_admin/main/
      connection_dashboard.html.erb    ← ERB template with loader
  config/
    locales/
      en.yml                           ← updated with action label
      it.yml                           ← updated with action label
```

The action file (`connection_dashboard.rb`) registers the entry in the `rails_admin` sidebar:

```ruby
module RailsAdmin
  module Config
    module Actions
      class ConnectionDashboard < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)
        register_instance_option :root? do true end
        register_instance_option :collection? do false end
        register_instance_option :member? do false end
        register_instance_option :link_icon do 'fa fa-dashboard' end
        register_instance_option :http_methods do [:get, :post] end
        register_instance_option :controller do
          proc do
            # controller logic here
          end
        end
      end
    end
  end
end
```

The JavaScript file sets up an ActionCable subscription for real-time updates:

```javascript
// ActionCable subscription for connection_dashboard
document.addEventListener('DOMContentLoaded', () => {
  const consumer = ActionCable.createConsumer();
  consumer.subscriptions.create({ channel: 'ConnectionDashboardChannel' }, {
    received(data) { /* update UI */ }
  });
});
```

**Example workflow:**

```
1. Right-click vendor/submodules/tcp_debugger in the Explorer.
2. Select "Thecore 3: Add a Root Action".
3. Enter: connection_dashboard
4. The action appears in the rails_admin sidebar after reloading the server.
```

---

### 4.7 Add a member action

**Command:** `Thecore 3: Add a Member Action`

**When to use:** when you need a button or link on each row of a model's list view in `rails_admin` — for example, a "Test connection" button on each `TcpConnection` row.

**How to invoke:** right-click on the **ATOM root folder** inside `vendor/submodules/` and select "Thecore 3: Add a Member Action".

**Inputs requested:**

| Input | Format | Example |
|---|---|---|
| Action name | snake_case | `test_connection` |

**What it generates:**

```
vendor/submodules/tcp_debugger/
  lib/
    member_actions/
      test_connection.rb          ← RailsAdmin member action definition
  app/
    assets/
      javascripts/rails_admin/actions/
        test_connection.js        ← XHR / form submission handler
      stylesheets/rails_admin/actions/
        test_connection.scss
    views/rails_admin/main/
      test_connection.html.erb
  config/
    locales/
      en.yml                      ← updated
      it.yml                      ← updated
```

Unlike root actions, member actions operate on a specific model instance. The action definition specifies which models the button appears for:

```ruby
register_instance_option :visible? do
  authorized? && bindings[:object].is_a?(TcpConnection)
end
```

The JavaScript handles the interaction:
- A **GET request** can be used to fetch and display information client-side without a page reload.
- A **PATCH form submission** can trigger a state change on the object.

**Example workflow:**

```
1. Right-click vendor/submodules/tcp_debugger in the Explorer.
2. Select "Thecore 3: Add a Member Action".
3. Enter: test_connection
4. Edit the generated controller proc to implement the test logic.
5. Edit the ERB template to display the result.
```

---

## 5. Model anatomy

Every model generated by Thecore gets three concern files. Here is the full content and purpose of each.

### `concerns/api/tcp_connection.rb`

Controls how the model is serialised in API responses. Uses `ModelDrivenApi.smart_merge` to compose the JSON attributes configuration:

```ruby
module Api::TcpConnection
  extend ActiveSupport::Concern

  included do
    # Use self.json_attrs to drive json rendering for
    # API model responses (index, show and update ones).
    # Accepted keys:
    #   only:    fields to include
    #   except:  fields to exclude
    #   methods: model methods to include in output
    #   include: associated models (accepts the same keys recursively)
    cattr_accessor :json_attrs
    self.json_attrs = ::ModelDrivenApi.smart_merge (json_attrs || {}), {}

    # Custom API actions are defined in concerns/endpoints/
  end
end
```

**Example — expose only safe fields:**

```ruby
self.json_attrs = ::ModelDrivenApi.smart_merge (json_attrs || {}), {
  only: [:id, :host, :port, :status],
  include: { logs: { only: [:id, :message, :created_at] } }
}
```

### `concerns/rails_admin/tcp_connection.rb`

Configures the `rails_admin` admin UI for this model:

```ruby
module RailsAdmin::TcpConnection
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label I18n.t('admin.registries.label')
      navigation_icon  'fa fa-plug'
    end
  end
end
```

**Example — customise the list and edit views:**

```ruby
rails_admin do
  navigation_label I18n.t('admin.registries.label')
  navigation_icon  'fa fa-plug'

  list do
    field :host
    field :port
    field :status
    field :created_at
  end

  edit do
    field :host
    field :port
  end
end
```

### `concerns/endpoints/tcp_connection.rb`

Defines custom non-CRUD API actions. The class inherits from `NonCrudEndpoints` and each action is documented inline using OpenAPI/Swagger notation:

```ruby
class Endpoints::TcpConnection < NonCrudEndpoints
  # Uncomment and edit to add a custom endpoint:
  #
  # self.desc 'TcpConnection', :ping, {
  #   get: {
  #     summary:     "Ping a TCP connection",
  #     description: "Attempts to reach the host and port and returns the result",
  #     operationId: "ping",
  #     tags:        ["TcpConnection"],
  #     parameters: [
  #       { name: "explain", in: "query", required: true,
  #         schema: { type: "boolean" } }
  #     ],
  #     responses: {
  #       200 => { description: "Ping result",
  #                content: { "application/json": { schema: { type: "object",
  #                  additionalProperties: true } } } },
  #       501 => { error: :string }
  #     }
  #   }
  # }
  # def ping(params)
  #   { reachable: true, latency_ms: 12 }, 200
  # end
end
```

---

## 6. Deploy

### Production Docker images

The project builds three Docker images, each layered on the previous one:

| Image | Dockerfile | Purpose |
|---|---|---|
| `gabrieletassoni/thecore-common:<version>` | `Dockerfile.common` | Base Ruby + OS dependencies |
| `gabrieletassoni/thecore:<version>` | `Dockerfile.deploy` | Production Rails image (bundler configured for production) |
| `gabrieletassoni/vscode-devcontainers-thecore:<version>` | `Dockerfile.dev` | Devcontainer image (Docker, Node, Rails, `vsce`) |

**Version scheme:** `<major>.<year>.<month>.<day>` — e.g. `3.2024.3.15`. The major version is read from the `version` file in the repository root.

**To build and push all images:**

```bash
# Requires: docker login
bin/build
```

This runs `bin/build-common`, `bin/build-for-dev`, `bin/build-for-deploy` in sequence, each of which builds its image and pushes it to Docker Hub.

### Application deployment

A Thecore application is deployed as a set of Docker Compose services defined in `docker/docker-compose.yml`:

| Service | Image | Purpose |
|---|---|---|
| `db` | `postgres:15-bookworm` | PostgreSQL database |
| `cache` | `eqalpha/keydb` | Redis-compatible cache (Sidekiq backend) |
| `backend` | app image | Rails server (entrypoint: `entrypoint.sh`) |
| `worker` | app image | Sidekiq worker (entrypoint: `entrypoint-sidekiq.sh`) |

The `backend` entrypoint runs the following steps in sequence, stopping with an error if any step fails:

```
db:create → db:migrate → thecore:db:seed → assets:clobber → assets:precompile → rails server
```

The `docker-compose.net.yml` overlay wires all services to a `webproxy` Docker network, where an Nginx reverse proxy (e.g. `jwilder/nginx-proxy`) automatically picks up the `VIRTUAL_HOST` environment variable and routes HTTPS traffic.

### Multi-target deployment

The `vendor/deploytargets/` directory holds one sub-folder per deployment provider. Each provider folder contains:

- A `docker_host` file (for production) or `docker_<env>_host` file (for staging/UAT) with the SSH URL of the Docker host.
- One `.env` file per customer/tenant with all required environment variables (`SECRET_KEY_BASE`, `ADMIN_PASSWORD`, `APP_NAME`, etc.).
- Optionally, an `image` file to use a custom backend image name.

The `scripts/docker-deploy.sh` script iterates over all providers and customers, SSHes into each Docker host, and runs `docker compose up -d` with the appropriate `.env` file. This makes multi-tenant, multi-host deployment fully automated.

**Required environment variables per customer `.env`:**

```env
SECRET_KEY_BASE=<random 128-char hex>
ADMIN_PASSWORD=<initial admin password>
APP_NAME=My Application
COMPOSE_PROJECT_NAME=my_app_prod
BE_SUBDOMAIN=api
FE_SUBDOMAIN=app
BASE_DOMAIN=example.com
IMAGE_TAG_BACKEND=registry.example.com/myapp/backend:3.2024.3.15
```

### CI/CD

**GitLab CI** (`.gitlab-ci.yml` generated in both the main app and each ATOM):
- On tag push: builds the Docker image, pushes to the GitLab registry, deploys to all configured targets via `scripts/docker-deploy.sh`.

**GitHub Actions** (`.github/workflows/gempush.yml` generated in each ATOM):
- On tag push: runs `gem build` and `gem push` to publish the ATOM gem to RubyGems.org (or a private Gem server if `GITLAB_GEM_REPO_TARGET` is set).

The devcontainer image itself is rebuilt weekly via the GitHub Actions workflow in this repository (`.github/workflows/main.yml`), triggered every Sunday at midnight.

---

## 7. Command reference

### Main application context

> Right-click on any folder **outside** `vendor/submodules/`

| Command | What it does |
|---|---|
| **Thecore 3: Setup Devcontainer** | Generates `.devcontainer/` configuration for the workspace |
| **Thecore 3: Create an App** | Scaffolds a complete Thecore Rails application |
| **Thecore 3: Create an ATOM** | Creates a new Rails engine under `vendor/submodules/` |
| **Thecore 3: Add a Model** | Generates a model + migration + 3 concerns in the main app |

### ATOM context

> Right-click on a folder **directly inside** `vendor/submodules/`

| Command | Inputs | What it does |
|---|---|---|
| **Thecore 3: Add a Model** | Model name (PascalCase), fields | Generates model + migration + 3 concerns inside the ATOM |
| **Thecore 3: Add a DB Migration** | Migration name (PascalCase), fields | Generates a migration and moves it into the ATOM |
| **Thecore 3: Add a Root Action** | Action name (snake_case) | Generates a `rails_admin` main-menu section with controller, view, assets, i18n |
| **Thecore 3: Add a Member Action** | Action name (snake_case) | Generates a `rails_admin` per-row action with controller, view, assets, i18n |

### Input validation rules

| Input type | Rule | Example |
|---|---|---|
| Model name | Must be PascalCase, letters only | `TcpConnection` ✓ — `tcp_connection` ✗ |
| Action name | Must be snake_case, lowercase letters, digits, underscores | `test_connection` ✓ — `TestConnection` ✗ |
| Migration fields | Space-separated `field:type` pairs | `host:string port:integer` ✓ |
| ATOM name | Free text, converted to snake_case automatically | `TCP Debugger` → `tcp_debugger` |
| Email | Must be a valid email address | `user@example.com` ✓ |
| URL | Must be a valid URL | `https://github.com/acme/atom` ✓ |

---

## 8. Further reading

| Topic | Document |
|---|---|
| REST API reference (authentication, endpoints, search, schema, DSL) | [REST_API.md](REST_API.md) |
| ActionCable topics, namespaces, and usage from Ruby/JavaScript clients | [ACTIONCABLE.md](ACTIONCABLE.md) |
| Platform-specific environment setup | [Linux](SETUP_VSCODE_LINUX.md) · [Windows](SETUP_VSCODE_WINDOWS.md) · [macOS](SETUP_VSCODE_MACOS.md) |
