# Authentication Integrations

**Thecore** ships with a layered authentication system built on [Devise](https://github.com/heartcombo/devise). The base layer provides local (database-backed) authentication. On top of that, three optional integrations can be enabled independently:

| Integration | Activation mechanism |
|---|---|
| LDAP / Active Directory | Add one or more records in the `ldap_servers` table (via Rails Admin) |
| Google OAuth2 | Set `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` environment variables |
| Microsoft Entra ID (Azure AD) | Set `ENTRA_CLIENT_ID` + `ENTRA_CLIENT_SECRET` + `ENTRA_TENANT_ID` environment variables |

All three can coexist. The login page automatically shows only the buttons/flows that are currently configured.

---

## 1. Local Authentication (always active)

Every Thecore application includes local authentication out of the box via Devise `database_authenticatable`. Users are stored in the `users` table with a hashed password.

**Password policy** (enforced by the `User` model):

| Rule | Default | Override |
|---|---|---|
| Minimum length | 8 characters | `MIN_PASSWORD_LENGTH` env var |
| Maximum length | 128 characters | — |
| Must contain | ≥1 uppercase, ≥1 lowercase, ≥1 digit, ≥1 special character | — |

**Session timeout** defaults to 31 minutes and is configurable via:

```bash
SESSION_TIMEOUT_IN_MINUTES=60
```

---

## 2. LDAP / Active Directory

### How it works

Authentication is attempted in two steps:

1. Devise checks the local database first.
2. If local auth fails, `Ldap::Authenticator` iterates through all configured LDAP servers (ordered by `priority`) and tries to bind with the supplied credentials.

If any LDAP server accepts the bind, the user is signed in. The corresponding `users` row is created or updated automatically, and `auth_source` is set to the LDAP server's identifier.

LDAP users can also be bulk-imported and kept in sync via a background job or a rake task (see [Sync](#ldap-user-sync) below).

### Enabling LDAP

No environment variables are needed. LDAP is enabled **by adding rows to the `ldap_servers` table** through the Rails Admin interface (`/admin/ldap_server`).

### `ldap_servers` table reference

| Column | Type | Default | Description |
|---|---|---|---|
| `host` | string | — | Hostname or IP of the LDAP/AD server |
| `port` | integer | `389` | Port (use `636` for LDAPS) |
| `base_dn` | string | — | Base Distinguished Name for searches, e.g. `DC=company,DC=com` |
| `admin_user` | string | — | DN or UPN of the service account used for admin binds |
| `admin_password` | string | — | Password for the service account |
| `use_ssl` | boolean | `false` | Enable LDAPS (TLS). Set to `true` when `port` is `636` |
| `auth_field` | string | `userPrincipalName` | LDAP attribute matched against the login email |
| `priority` | integer | `1` | Lower value = tried first when multiple servers are configured |
| `name` | string | — | LDAP attribute to read for the user's first name |
| `surname` | string | — | LDAP attribute to read for the user's last name |
| `phone` | string | — | LDAP attribute to read for the user's phone number |
| `code` | string | — | Arbitrary identifier for this server (used as `auth_source` value) |

### Typical Active Directory configuration

| Field | Example value |
|---|---|
| `host` | `ad.company.com` |
| `port` | `389` (or `636` + `use_ssl: true`) |
| `base_dn` | `DC=company,DC=com` |
| `admin_user` | `svc-thecore@company.com` |
| `auth_field` | `userPrincipalName` |
| `name` | `givenName` |
| `surname` | `sn` |

### Role mapping from LDAP groups

During import/sync, group membership is read from the LDAP directory and mapped to Thecore roles:

- Members of **Domain Admins** or **Administrators** LDAP groups are granted `admin: true`.
- All other groups are matched by name to existing Thecore `Role` records and assigned accordingly.

Roles that no longer appear in the LDAP response are removed from the user on the next sync.

### LDAP user sync

**Rake task** (run manually or from a cron job):

```bash
bundle exec rake ldap:sync_users
```

**Background job** (enqueue from Rails console or scheduler):

```ruby
BackgroundLdapImportJob.perform_later
```

The job calls `ThecoreAuthCommons.import_ldap_users_task`, which:

1. Connects to each LDAP server using the admin credentials.
2. Searches all users matching the configured attribute filters.
3. Creates or updates matching `users` rows (email is the unique key).
4. Assigns roles based on group membership.
5. Preserves active sessions — existing signed-in users are not invalidated.

### Multiple LDAP servers

Add one row per server. Servers are tried in ascending `priority` order during both interactive login and batch import. This allows cascading from a primary DC to a fallback replica.

---

## 3. Google OAuth2

### How it works

When the environment variables are present, an **"Sign in with Google"** button appears on the login page. Clicking it redirects the user to Google's consent screen. On return, Thecore's `OmniauthCallbacksController#google` handler:

1. Extracts the user's email, first name, and last name from the OAuth payload.
2. Looks up or creates a local `users` row.
3. Signs the user in if they are not locked.

### Enabling Google OAuth2

Set the following environment variables **before starting the Rails server**:

```bash
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
```

If either variable is missing or empty, the Google OAuth flow is completely disabled — no button is shown and the OmniAuth route is not registered.

### Google Cloud Console setup

1. Go to [console.cloud.google.com](https://console.cloud.google.com) → **APIs & Services** → **Credentials**.
2. Create an **OAuth 2.0 Client ID** of type **Web application**.
3. Add your application's callback URL to **Authorized redirect URIs**:
   ```
   https://yourapp.example.com/users/auth/google_oauth2/callback
   ```
4. Copy the **Client ID** and **Client secret** into the environment variables above.

### OmniAuth settings (applied automatically)

| Setting | Value |
|---|---|
| Scope | `email,profile` |
| Prompt | `select_account` (always shows account picker) |
| Access type | `online` (no refresh tokens) |
| Allowed request methods | GET and POST |

---

## 4. Microsoft Entra ID (Azure AD)

### How it works

When the three Entra ID environment variables are present, a **"Sign in with Microsoft"** button appears on the login page. The flow uses the `omniauth-microsoft_graph_mailer` strategy (OpenID Connect / Microsoft Graph). On callback, `OmniauthCallbacksController#microsoft` runs the same lookup-or-create logic as the Google flow.

### Enabling Entra ID

Set all three variables **before starting the Rails server**:

```bash
ENTRA_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ENTRA_CLIENT_SECRET=your-client-secret
ENTRA_TENANT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

If any of the three is missing or empty, the Entra ID flow is completely disabled.

### Azure Portal setup

1. Go to [portal.azure.com](https://portal.azure.com) → **Microsoft Entra ID** → **App registrations** → **New registration**.
2. Set the **Redirect URI** (Web platform):
   ```
   https://yourapp.example.com/users/auth/entra_id/callback
   ```
3. Under **Certificates & secrets**, create a new **Client secret** and copy the value immediately.
4. From the **Overview** page, copy the **Application (client) ID** → `ENTRA_CLIENT_ID` and the **Directory (tenant) ID** → `ENTRA_TENANT_ID`.
5. Under **API permissions**, ensure `openid`, `profile`, `email`, and `User.Read` (Microsoft Graph, Delegated) are granted.

### OmniAuth settings (applied automatically)

| Setting | Value |
|---|---|
| Scope | `openid profile email User.Read` |
| Response type | `code` |
| Allowed request methods | GET and POST |

---

## 5. How the integrations interact

All four authentication methods share the same `users` table. The `auth_source` column records how a user was last authenticated:

| Value | Meaning |
|---|---|
| `local` | Created or last authenticated via Devise local login |
| `google` | Authenticated via Google OAuth2 |
| `entra_id` | Authenticated via Microsoft Entra ID |
| _(ldap server code)_ | Authenticated or imported via LDAP (value equals the `code` field of the matching `ldap_servers` row) |

A user can only be active through one auth source at a time. If a user exists locally and later signs in via OAuth, the record is updated but no duplicate is created.

### Precedence during login

1. **Local Devise** — checked first on every login attempt.
2. **LDAP** — checked only if local auth fails; servers are tried in priority order.
3. **Google / Entra ID** — separate button flows, never fall through to local or LDAP.

---

## 6. Environment variable quick reference

```bash
# Session
SESSION_TIMEOUT_IN_MINUTES=30   # optional, default 30
MIN_PASSWORD_LENGTH=8            # optional, default 8

# Google OAuth2 (both required to enable)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=

# Microsoft Entra ID (all three required to enable)
ENTRA_CLIENT_ID=
ENTRA_CLIENT_SECRET=
ENTRA_TENANT_ID=
```

LDAP is configured entirely in the database — no environment variables required.

---

## 7. Gem dependencies

The `thecore_auth_commons` gem includes all required dependencies:

| Gem | Purpose |
|---|---|
| `devise` | Core authentication framework |
| `omniauth` | OAuth2 middleware |
| `omniauth-google-oauth2` | Google provider strategy |
| `omniauth-microsoft_graph_mailer` | Entra ID / Microsoft Graph strategy |
| `net-ldap` | LDAP protocol client |
| `cancancan` | Role-based access control (RBAC) |
