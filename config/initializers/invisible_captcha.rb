# frozen_string_literal: true

InvisibleCaptcha.setup do |config|
  # Request specs can't satisfy the timing and spinner checks, so test keeps the honeypot only.
  config.timestamp_enabled = !Rails.env.test?
  config.spinner_enabled = !Rails.env.test?
end
