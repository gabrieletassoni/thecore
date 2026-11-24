require "test_helper"

# System tests run on demand only (`bin/rails test:system`), never in CI: the CI samples run
# `bin/rails test`, which skips test/system (ADR 0010 in the thecore repo). In the devcontainer the
# browser is the `selenium` service: SELENIUM_URL points at it, and the app under test listens on
# 0.0.0.0 so that browser can reach it through the app container's hostname. Without SELENIUM_URL a
# local headless Chrome is used.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Warden::Test::Helpers

  SCREEN_SIZE = [ 1400, 1400 ].freeze
  PASSWORD = "Password123!"

  # Text that only an error page shows.
  ERROR_MARKERS = [ "We're sorry, but something went wrong", "Routing Error", "NoMethodError",
                    "ActionView::Template::Error", "Internal Server Error",
                    "The page you were looking for doesn't exist", "undefined method" ].freeze

  if ENV["SELENIUM_URL"].present?
    driven_by :selenium, using: :headless_chrome, screen_size: SCREEN_SIZE,
                         options: { browser: :remote, url: ENV.fetch("SELENIUM_URL") } do |options|
      options.add_option("goog:loggingPrefs", { browser: "ALL" })
    end

    Capybara.server_host = "0.0.0.0"
    Capybara.app_host = "http://#{Socket.gethostname}"
    Capybara.always_include_port = true
  else
    driven_by :selenium, using: :headless_chrome, screen_size: SCREEN_SIZE do |options|
      options.add_option("goog:loggingPrefs", { browser: "ALL" })
    end
  end

  # CSRF protection is off in the test environment, so pages would render no csrf-token meta and
  # forms would skip the check. The browser should see what production serves.
  setup do
    clear_console
    @forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @forgery_protection
    Warden.test_reset!
  end

  def create_user(label = "user", **attrs)
    User.create!(email: "#{label}-#{SecureRandom.hex(4)}@example.com", password: PASSWORD,
                 password_confirmation: PASSWORD, **attrs)
  end

  # The devcontainer's `ldap` service, with its admin (.devcontainer/ldap-users.ldif has its users).
  def create_ldap_server
    LdapServer.create!(host: "ldap", port: 389, base_dn: "dc=example,dc=com",
                       admin_user: "cn=admin,dc=example,dc=com", admin_password: "admin",
                       auth_field: "mail", name: "givenName", surname: "sn")
  end

  def sign_in_through_form(email, password)
    visit "/app"
    fill_in "user[email]", with: email
    fill_in "user[password]", with: password
    find("form [type=submit]").click
  end

  # Routes load lazily in tests (Rails 8), and Devise sets up Warden's session serializer only when
  # they load: without this the first request would store the whole User in the session.
  def sign_in_as(user)
    Rails.application.reload_routes_unless_loaded
    login_as(user, scope: :user)
  end

  # The page isn't an error page, every resource it loaded answered below 400, and the browser
  # console has no errors. `except` drops resources and console lines matching any of the strings.
  def assert_page_healthy(context = current_url, except: [])
    problems = page_problems.reject { |line| except.any? { |e| line.include?(e) } }

    assert_empty problems, "#{context}: #{problems.join(' | ')}"
  end

  # The browser asks for /favicon.ico on its own, and an app may well not have one.
  def page_problems
    ERROR_MARKERS.select { |m| page.html.include?(m) } +
      failed_resources.reject { |r| r.include?("favicon") }.map { |r| "resource #{r}" } +
      console_errors.map { |m| "console #{m}" }
  end

  # Console lines at SEVERE level since the last call (the browser hands each line out once).
  def console_errors
    console_log.select { |l| l.level == "SEVERE" }.map(&:message).reject { |m| m.include?("favicon") }
  end

  def console_log
    page.driver.browser.logs.get(:browser)
  end

  # Drops what earlier tests left in the browser's console: the browser session outlives a test.
  alias clear_console console_log

  def failed_resources
    page.evaluate_script(<<~JS)
      performance.getEntriesByType('resource')
        .filter(e => e.responseStatus && e.responseStatus >= 400)
        .map(e => e.responseStatus + ' ' + e.name)
    JS
  end

  # Polls the block until it returns a truthy value, or fails with `message` after `timeout`.
  def wait_for(message, timeout: 10)
    deadline = Time.current + timeout
    loop do
      result = yield
      return result if result

      flunk "#{message} (waited #{timeout}s)" if Time.current > deadline
      sleep 0.2
    end
  end

  # RailsAdmin's save and delete buttons can sit under a sticky bar: a JS click avoids
  # "element click intercepted".
  def js_click(element)
    page.execute_script("arguments[0].click()", element)
  end
end
