# frozen_string_literal: true

# General helpers for system specs (auth, URLs, navigation, assertions)
module SystemHelpers
  # Build a URL for the admin subdomain with the current test server port
  def admin_url(path)
    port = Capybara.current_session.server.port
    "http://admin.lvh.me:#{port}#{path}"
  end

  # Build a URL for the public site with the current test server port
  def public_url(path)
    port = Capybara.current_session.server.port
    "http://lvh.me:#{port}#{path}"
  end

  # Named sign_in_as to avoid collision with Warden::Test::Helpers#login_as.
  # Waits for the post-login page to load before returning, preventing race
  # conditions where the next `visit` fires before authentication completes.
  def sign_in_as(user)
    visit admin_url("/users/sign_in")
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_button "Log in"
    assert_has_flash(:success, "Signed in successfully.")
  end

  def assert_has_flash(type, message = nil)
    alert_class = type == :success ? "alert-success" : "alert-error"
    selector = "[role='alert'].#{alert_class}, .flashes .alert-#{type}"
    if message
      expect(page).to have_css(selector, text: message)
    else
      expect(page).to have_css(selector)
    end
  end

  def click_sidebar(href)
    within ".sidebar-sticky" do
      link = page.find(:css, "a[href*='#{href}']")
      visit link["href"]
    end
  end

  def find_element_with_retry(max_attempts: 3)
    attempts = 0
    begin
      yield
    rescue Capybara::ElementNotFound => e
      attempts += 1
      retry if attempts < max_attempts
      raise e
    end
  end

  def suppress_stdout
    stdout = $stdout
    $stdout = File.open(File::NULL, "w")
    yield
  ensure
    $stdout = stdout
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
  config.include SystemHelpers, type: :feature
end
