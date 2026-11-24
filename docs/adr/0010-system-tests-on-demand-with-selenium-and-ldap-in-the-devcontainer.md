# System tests on demand, with Selenium and LDAP in the devcontainer

A Thecore host app's admin UI (RailsAdmin, the ATOMs' custom actions, the UJS views) was checked by hand or with one-off Selenium scripts before each release, such as the RailsAdmin acceptance check for MyTask's move to Rails 8.1 (Odoo #6090). Rails system tests make that repeatable, but the devcontainer image has no browser, and `LdapServer` (`thecore_auth_commons`) can only be exercised against a real LDAP server.

**Decision**: the sample devcontainer (`samples/devcontainer/docker-compose.yml`) runs two more services, always on like `db` and `redis`:

- `selenium` (`selenium/standalone-chromium`): the app container gets `SELENIUM_URL=http://selenium:4444`, and the app's `ApplicationSystemTestCase` drives that remote browser, serving the app under test on `0.0.0.0` so the browser can reach it. Without `SELENIUM_URL` it falls back to a local headless Chrome.
- `ldap` (`osixia/openldap:1.5.0`), bootstrapped from `.devcontainer/ldap-users.ldif` with one test user, so system tests can check the LDAP server test action and a real LDAP login.

System tests run **on demand** (`bin/rails test:system`), as an acceptance check before a release or after a framework upgrade. They stay out of the CI `tests` job, which runs `bin/rails test` and so never loads `test/system/`.

`thecore_generators`' App template fetches that `ApplicationSystemTestCase` and a smoke system test from `samples/test/` (an admin signs in, an LDAP-only user signs in); Rails 8.1 itself writes the system test case only with `--devcontainer`. `thecore_code_extension`'s devcontainer templates carry the same two services. MyTask (`mytask-imas` backend) is the first adopter and the source of the first full suite. Existing host apps adopt it by hand.

## Considered options

- **Chromium in the devcontainer image**: makes the image every app uses heavier, and its version is coupled to the image's release cycle. The standalone image ships a matching browser and driver.
- **Start the services on demand** (a compose profile): saves about 200 MB of idle memory, but someone has to remember to start them, which defeats "run them whenever needed".
- **System tests in CI**: they're slow, need a browser service in every pipeline, and break on UI timing. As a manual check they cost nothing when nobody runs them. A manual CI job can be added later without changing the tests.
- **A closed port instead of an LDAP server**: it proves only that the form's AJAX round trip works. A real server also proves the bind succeeds and that a user can log in.

## Consequences

- Every devcontainer created from the samples runs Selenium and OpenLDAP. Containers are created when the devcontainer is (re)built.
- `osixia/openldap` hasn't been updated since 2021. It's a test fixture only, never a production LDAP; replace it if it stops working.
