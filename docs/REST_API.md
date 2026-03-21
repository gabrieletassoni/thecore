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
| Authorisation | [CanCanCommunity/cancancan](https://github.com/CanCanCommunity/cancancan) |
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

## Authentication & Token Management

The API implements a **stateless JWT (JSON Web Token)** authentication mechanism with two distinct phases:

1. **Initial Authentication:** Exchanging credentials for the first token.
2. **Session Maintenance:** Using a **Sliding Expiration** strategy where every subsequent successful request issues a fresh token.

### 1. Initial Authentication (Login)

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

Upon successful authentication, the server returns two critical pieces of data:

1. **Response Body:** The User object.
2. **Response Header:** The initial JWT in the `token` header.

Example response body:

```json
{
  "id": 219,
  "email": "admin@example.com",
  "created_at": "2025-12-10T07:57:54.336Z",
  "admin": true,
  "locked": false,
  "locale": "en",
  "roles": []
}
```

Example response headers:

```http
HTTP/1.1 200 OK
content-type: application/json; charset=utf-8
token: eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoyMTksImV4cCI6MTc2NjQ3ODMwN30...
```

### 2. Using the Token

```
Authorization: Bearer <token>
```

### 3. Sliding Expiration (Token Renewal)

Instead of a fixed expiration that forces a re-login, the API issues a **brand new token** in the response header of every successfully authenticated request.

**Renewal flow:**

1. The client sends its current token in the `Authorization` header.
2. The server verifies the token and sets `@current_user`.
3. Before responding, the server generates a new JWT and sets it in the response header:

```ruby
response.set_header("Token", JsonWebToken.encode(user_id: current_user.id))
```

**Client-side implementation guide:**

1. **Login:** Call `/api/v2/authenticate` and store the `token` from the response header.
2. **Subsequent requests:** Attach the stored token as `Authorization: Bearer <token>`.
3. **Update storage:** After every response, check for a `Token` header.
   - **If present:** Immediately replace the stored token with the new value.
   - **If absent:** Continue using the existing token (unless the response was 401/403).

**Failure scenarios:**

If the token is expired or has an invalid signature, the server returns 401 and does **not** include a new token in the header. The client must perform the Initial Authentication (login) again.

### 4. Heartbeat / Token Refresh

```
GET /api/v2/info/heartbeat
```

Returns a new token without performing any other action. Use this to keep a session alive without making a real request.

---

## CRUD endpoints

All model endpoints require authentication. Replace `:model` with the pluralised, snake_case model name (e.g. `users`, `vehicles`).

| Action | Method | URL | Body |
|---|---|---|---|
| List | `GET` | `/api/v2/:model` | — |
| Show | `GET` | `/api/v2/:model/:id` | — |
| Search | `POST` | `/api/v2/:model/search` | Ransack `q` hash |
| Create | `POST` | `/api/v2/:model` | Model attributes |
| Update | `PUT` | `/api/v2/:model/:id` | Full model attributes |
| Patch | `PATCH` | `/api/v2/:model/:id` | Partial model attributes |
| Delete | `DELETE` | `/api/v2/:model/:id` | — |

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

## Filtering, Searching, and Pagination

The controller unifies params via `request.parameters`, so the filtering logic is **identical** whether parameters are passed as a Query String (GET) or as a JSON Body (POST to the `/search` endpoint).

### Pagination and counting

| Parameter | Type | Effect |
|---|---|---|
| `page` | Integer | Page number to retrieve |
| `per` | Integer | Records per page (works with `page`) |
| `count` | Any | If present and non-empty, returns `{ "count": N }` instead of records |

### Ransack filters (`q` parameter)

The `q` parameter drives filtering via the [Ransack](https://github.com/activerecord-hackery/ransack) gem. Basic structure: `q[field_name_predicate]=value`.

| Predicate | Effect |
|---|---|
| `_eq` | Equal to |
| `_cont` | Contains (LIKE %value%, case-insensitive) |
| `_start` | Starts with |
| `_end` | Ends with |
| `_gt` / `_lt` | Greater than / Less than |
| `_gteq` / `_lteq` | Greater than or equal to / Less than or equal to |
| `_in` | Included in a list (accepts an array) |
| `_present` | Non-null values (`1` or `true`); use `_blank` for nulls |

Sorting: `q[s]=field_name asc` or `q[s]=field_name desc`.

See the [Ransack documentation](https://github.com/activerecord-hackery/ransack/wiki) for the full predicate reference.

### Client-side field selection (`a` parameter)

The `a` (or `json_attrs`) parameter lets the client specify exactly which fields to receive without changing any backend code:

| Key | Type | Effect |
|---|---|---|
| `only` | Array | Include only these fields |
| `except` | Array | Exclude these fields |
| `methods` | Array | Include results of these model methods |
| `include` | Object | Include associated models (accepts the same keys recursively) |

Example — select specific fields and a method:

```
GET /api/v2/users?a[only][]=locked&a[only][]=username&a[methods][]=jwe_data
```

Returns:

```json
[
  {
    "username": "Administrator",
    "locked": false,
    "jwe_data": "eyJhbGci..."
  }
]
```

---

## Practical Examples: GET vs POST

Since the filtering logic is identical for both methods, choose based on query complexity:

- **GET** — simple queries, easy to share as a URL.
- **POST** to `/search` — complex nested queries, avoids URL length limits, more readable.

### Scenario A — Simple search with pagination

Find users whose name contains "Mario", page 2, 10 per page.

**GET:**

```
GET /api/v2/users?q[name_cont]=Mario&page=2&per=10
```

**POST:**

```json
POST /api/v2/users/search

{
  "q": { "name_cont": "Mario" },
  "page": 2,
  "per": 10
}
```

### Scenario B — Advanced search with sorting and field selection

Find orders where `total_price > 50`, user email ends with `@test.com`, sorted by creation date descending, returning only `id`, `total_price`, and the associated user's `email`.

**GET:**

```
GET /api/v2/orders?q[total_price_gt]=50&q[user_email_end]=@test.com&q[s]=created_at desc&a[only][]=id&a[only][]=total_price&a[include][user][only][]=email
```

**POST:**

```json
POST /api/v2/orders/search

{
  "q": {
    "total_price_gt": 50,
    "user_email_end": "@test.com",
    "s": "created_at desc"
  },
  "a": {
    "only": ["id", "total_price"],
    "include": {
      "user": { "only": ["email"] }
    }
  }
}
```

### Scenario C — Multiple values (OR) with `_in`

Find products where status is `"new"` **or** `"refurbished"`.

**GET:**

```
GET /api/v2/products?q[status_in][]=new&q[status_in][]=refurbished
```

**POST:**

```json
POST /api/v2/products/search

{
  "q": { "status_in": ["new", "refurbished"] }
}
```

### Scenario D — Count only

Know how many active users exist without downloading data.

**GET:**

```
GET /api/v2/users?q[active_eq]=true&count=true
```

**POST:**

```json
POST /api/v2/users/search

{
  "q": { "active_eq": true },
  "count": true
}
```

Expected response:

```json
{ "count": 156 }
```

---

## Custom actions

Custom actions are defined in `concerns/endpoints/<model>.rb` (see [GUIDE.md §5](GUIDE.md#5-model-anatomy)) and triggered via the `do` query parameter:

```
GET  /api/v2/:model?do=custom_action          # collection-level action
GET  /api/v2/:model/:id?do=custom_action      # member-level action
```

Custom actions can also be exposed as dedicated routes:

```
POST /api/v2/:model/custom_action/:action_name
```

---

## Info API

These endpoints expose metadata about the application. All except `/version` require authentication.

### Version

```
GET /api/v2/info/version
```

Returns the application version. No authentication required.

```json
{ "version": "3.2024.3.15" }
```

### Heartbeat

```
GET /api/v2/info/heartbeat
```

Returns a new token. Use to keep a session alive.

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

### Settings

```
GET /api/v2/info/settings
```

Returns the application settings.

### Swagger

```
GET /api/v2/info/swagger
```

Returns the self-generated OpenAPI/Swagger specification for all models in the application. The spec reflects the actual models present at runtime.

---

## Raw SQL

```
POST /api/v2/raw/sql
```

Executes a read-only SQL query directly on the underlying PostgreSQL database. Intended for complex reporting queries that cannot be expressed with Ransack.

**Restrictions:**

- Only `SELECT` statements are allowed.
- DDL and DML statements (`INSERT`, `UPDATE`, `DELETE`, `DROP`, etc.) are forbidden.
- The query **must** return a `result` key using `json_agg` or `jsonb_agg`.

### Request body

```json
{
  "query": "SELECT json_agg(u) AS result FROM users u WHERE u.active = true"
}
```

### Simple example

```sql
SELECT json_agg(u) AS result
FROM users u
WHERE u.active = true;
```

### Complex example with CTE

For queries joining multiple tables, use a CTE to keep the logic readable and to allow the SQL engine to optimise each step independently:

```sql
WITH pick_data AS (
  SELECT
    p.id,
    p.quantity,
    COALESCE(SUM(pr.quantity), 0) AS quantity_detected,
    json_agg(
      jsonb_build_object('id', pr.id, 'quantity', pr.quantity)
    ) AS project_rows
  FROM picks p
  LEFT JOIN project_rows pr ON pr.pick_id = p.id
  WHERE p.project_id = 16130
  GROUP BY p.id
)
SELECT jsonb_agg(pick_data) AS result
FROM pick_data;
```

The outer `SELECT jsonb_agg(...) AS result` is mandatory — the API reads the `result` key from the query output.

---

## ActiveStorage: File Uploads and Deletions

Rails models using `has_many_attached` expose their attachments through the API. Uploads require `multipart/form-data`; deletions use a virtual `remove_<attribute>` attribute.

### Uploading files (POST / PATCH)

Use `FormData` — do **not** set `Content-Type: application/json`. The browser (or HTTP client) must generate the `multipart/form-data` boundary automatically.

```javascript
const formData = new FormData();
formData.append('product[title]', title);

// Append each file individually — passing an array directly does not work
selectedFiles.forEach(file => {
  formData.append('product[assets][]', file);
});

await fetch('/api/v2/products', { method: 'POST', body: formData });
```

> **Common pitfall:** Never set `Content-Type: multipart/form-data` manually. The browser must set it automatically so the correct `boundary` is included.

**Raw HTTP equivalent:**

```http
POST /api/v2/products HTTP/1.1
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW

------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="product[title]"

My New Product
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="product[assets][]"; filename="photo.jpg"
Content-Type: image/jpeg

(binary data)
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

### Camera and gallery input (React / PWA)

```jsx
{/* Opens the rear camera directly on mobile */}
<input type="file" accept="image/*" capture="environment" multiple onChange={handleFileChange} />

{/* Lets the user choose between camera and gallery */}
<input type="file" accept="image/*" multiple onChange={handleFileChange} />
```

| `capture` value | Behaviour |
|---|---|
| `"environment"` | Opens rear camera directly |
| `"user"` | Opens front camera (selfie) |
| _(absent)_ | Device prompts: Take Photo or Photo Library |

### Deleting attachments (PATCH)

Send the ActiveStorage attachment IDs to remove via the `remove_<attribute>` virtual attribute:

```javascript
const formData = new FormData();

// New files to add (optional)
newFiles.forEach(file => formData.append('product[assets][]', file));

// IDs of existing attachments to delete
idsToRemove.forEach(id => formData.append('product[remove_assets][]', id));

await fetch(`/api/v2/products/${productId}`, { method: 'PATCH', body: formData });
```

**Raw HTTP equivalent:**

```http
PATCH /api/v2/products/100 HTTP/1.1
Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryXyZ123

------WebKitFormBoundaryXyZ123
Content-Disposition: form-data; name="product[remove_assets][]"

12
------WebKitFormBoundaryXyZ123
Content-Disposition: form-data; name="product[remove_assets][]"

45
------WebKitFormBoundaryXyZ123--
```

---

## References

- [Billy Cheng](https://medium.com/@billy.sf.cheng/a-rails-6-application-part-1-api-1ee5ccf7ed01) — JWT implementation on top of Devise
- [Daniel](https://medium.com/@tdaniel/passing-refreshed-jwts-from-rails-api-using-headers-859f1cfe88e9) — Token refresh via response headers

License: [MIT](https://opensource.org/licenses/MIT)
