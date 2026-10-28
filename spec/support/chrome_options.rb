# frozen_string_literal: true

module ChromeOptions
  module_function

  # Chrome checks each login against Google's breached-password list; a hit on "password" opens a dialog that swallows all real input (#3341).
  def disable_password_manager(options)
    options.add_preference(:credentials_enable_service, false)
    options.add_preference(:profile, password_manager_enabled: false, password_manager_leak_detection: false)
  end
end
