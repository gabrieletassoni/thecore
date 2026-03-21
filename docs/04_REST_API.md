# REST API Reference — Model Driven API

The `model_driven_api` gem provides a schema-driven REST API: every ActiveRecord model in the application gets a full set of CRUD endpoints automatically, with no per-model controller or route configuration required.

> **See also:** [GUIDE.md §5 Model anatomy](GUIDE.md#5-model-anatomy) for how to configure JSON serialisation per model using the `Api::ModelName` concern.

---

## Goals

- Comprehensive CRUD API generated automatically from ActiveRecord models and migrations.
- Client-driven JSON presentation: the client specifies which fields and associations to include in the response **without changing backend code** — overcoming a key limitation of plain REST versus GraphQL.

---

## Quick start (5 minutes)

```ruby
# Gemfile or *.gemspec
gem 'model_driven_api'
```

```bash
bundle install

# Add models via migrations
rails g migration AddLocation name:string:index description:text:index
rails g migration AddProduct name:string:index code:string:uniq location:references

rails db:migrate
rails thecore:db:seed
rails s
```

The seed step creates a default admin user. The initial password is stored in `.passwords` in the project root.

Use [Insomnia](https://insomnia.rest/) to explore the endpoints by importing the test collection from `test/insomnia/` and setting `base_url`, `email`, and `password` in the environment.

---

## Standards

| Concern | Library |
|---|---|
| Authentication | [JWT](https://github.com/jwt/ruby-jwt) |
| Authorisation | [CanCanCan](https://github.com/CanCanCommunity/cancancan) |
| Filtering / search | [Ransack](https://github.com/activerecord-hackery/ransack) |
| Routing | Catch-all rule mapping every AR model to CRUD endpoints |

---

## HTTP status codes

| Code | Meaning |
|---|---|
| 200 | Success |
| 401 | Unauthenticated — invalid credentials or token |
| 403 | Unauthorized — authenticated but lacks permission |
| 404 | Record or custom action not found |
| 422 | Validation failed |
| 500 | Server error (likely a bug) |

---

## Authentication

### Get a token

```
POST /api/v2/authenticate
```

Body:

```json
{
  "auth": {
    "email": "admin@example.com",
    "password": "secret"
  }
}
```

The response header contains the JWT. The token expires after 15 minutes. Each successful authenticated request returns a **new token** in the response header, so the client must update its stored token on every request.

### Use the token

```
Authorization: Bearer <token>
```

### Refresh the token

```
GET /api/v2/info/heartbeat
```

Returns a new token if the current one is still valid.

---

## CRUD endpoints

All model endpoints require authentication. Replace `:model` with the pluralised, snake_case model name (e.g. `users`, `vehicles`).

| Action | Method | URL | Body |
|---|---|---|---|
| List | `GET` | `/api/v2/:model` | — |
| Show | `GET` | `/api/v2/:model/:id` | — |
| Search | `POST` | `/api/v2/:model/search` | Ransack `q` hash |
| Create | `POST` | `/api/v2/:model` | Model attributes |
| Update | `PUT` | `/api/v2/:model/:id` | Partial model attributes |
| Delete | `DELETE` | `/api/v2/:model/:id` | — |

### Search body example

```json
{
  "q": {
    "id_eq": 1
  }
}
```

See the [Ransack documentation](https://github.com/activerecord-hackery/ransack/wiki) for the full predicate reference.

### Create body example

```json
{
  "user": {
    "email": "new@example.com",
    "admin": false,
    "password": "secret123",
    "password_confirmation": "secret123"
  }
}
```

### Update body example (partial update supported)

```json
{
  "user": {
    "email": "updated@example.com"
  }
}
```

---

## Custom actions

Custom actions are defined in `concerns/endpoints/<model>.rb` (see [GUIDE.md §5](GUIDE.md#5-model-anatomy)) and triggered via the `do` query parameter:

```
GET  /api/v2/:model?do=custom_action          # collection-level action
GET  /api/v2/:model/:id?do=custom_action      # member-level action
```

---

## Client-side field selection (`a` parameter)

The `a` (or `json_attrs`) query parameter lets the client specify exactly which fields to receive, without changing any backend code:

| Key | Type | Effect |
|---|---|---|
| `only` | Array | Include only these fields |
| `except` | Array | Exclude these fields |
| `methods` | Array | Include results of these model methods |
| `include` | Object | Include associated models (accepts the same keys recursively) |

**Example — select specific fields and a method:**

```
GET /api/v2/users?a[only][]=locked&a[only][]=username&a[methods][]=jwe_data
```

Translates to `{a: {only: ["locked", "username"], methods: ["jwe_data"]}}` and returns:

```json
[
  {
    "username": "Administrator",
    "locked": false,
    "jwe_data": "eyJhbGci..."
  }
]
```

**Combine with Ransack search:**

```
GET /api/v2/users?a[only][]=username&q[email_cont]=adm
```

For complex queries, use the `POST /api/v2/:model/search` endpoint instead of query strings.

---

## Info API

These endpoints expose metadata about the API. All except `/version` require authentication.

### Version

```
GET /api/v2/info/version
```

Returns the application version. No authentication required.

```json
{ "version": "3.2024.3.15" }
```

### Heartbeat / token refresh

```
GET /api/v2/info/heartbeat
```

Returns a new token. Use this to keep a session alive.

### Roles

```
GET /api/v2/info/roles
```

Returns all defined roles.

### Schema

```
GET /api/v2/info/schema
```

Returns all models accessible to the current user, with their field types, associations, and available custom actions:

```json
{
  "vehicles": {
    "id": "integer",
    "plate": "string",
    "status": "string",
    "associations": {
      "has_many": ["assignments"],
      "belongs_to": []
    },
    "methods": ["archive"]
  }
}
```

### DSL

```
GET /api/v2/info/dsl
```

Returns the `json_attrs` configuration for each model — which fields are included in list/show responses by default. Use this to drive automatic UI generation.

```json
{
  "vehicles": {
    "except": ["lock_version", "created_at", "updated_at"],
    "include": ["assignments"]
  }
}
```

### Translations

```
GET /api/v2/info/translations?locale=it
```

Returns all i18n translations for model and attribute names. The `locale` parameter defaults to `it`. Use the `activerecord.models` and `activerecord.attributes` keys to align client-side labels with the backend.

---

## References

- [Billy Cheng](https://medium.com/@billy.sf.cheng/a-rails-6-application-part-1-api-1ee5ccf7ed01) — JWT implementation on top of Devise
- [Daniel](https://medium.com/@tdaniel/passing-refreshed-jwts-from-rails-api-using-headers-859f1cfe88e9) — Token refresh via response headers

License: [MIT](https://opensource.org/licenses/MIT)
