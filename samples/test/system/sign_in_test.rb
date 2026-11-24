require "application_system_test_case"

# Smoke tests of a Thecore app in a browser: the sign-in form, RailsAdmin and an LDAP login against
# the devcontainer's `ldap` service. `bin/rails test:system`; never run by CI (ADR 0010 in thecore).
class SignInTest < ApplicationSystemTestCase
  test "an admin signs in through the Devise form and lands on the RailsAdmin dashboard" do
    admin = create_user("admin", admin: true)

    sign_in_through_form(admin.email, PASSWORD)

    assert_current_path "/app/"
    assert_selector "nav.navbar"
    assert_page_healthy
  end

  test "a user who exists only in LDAP signs in with the LDAP password" do
    create_ldap_server

    sign_in_through_form("ldap.user@example.com", "LdapPassword123!")

    assert_current_path "/app/"
    assert_text "ldap.user@example.com"
    assert_page_healthy
  end
end
