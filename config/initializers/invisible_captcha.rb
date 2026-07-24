# frozen_string_literal: true

InvisibleCaptcha.setup do |config|
  # The time-based and spinner checks can't be exercised deterministically
  # from request specs (the spinner value is minted per rendered form), so
  # keep only the honeypot in the test environment.
  config.timestamp_enabled = !Rails.env.test?
  config.spinner_enabled = !Rails.env.test?
end
