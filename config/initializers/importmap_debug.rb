# frozen_string_literal: true

# Temporary debug logging for importmap asset resolution issue
# Remove this file after the staging importmap issue is resolved

# rubocop:disable Rails/UnknownEnv
if Rails.env.staging?
  Rails.application.config.after_initialize do
    Rails.logger.info '=== IMPORTMAP DEBUG (boot) ==='
    Rails.logger.info "assets.resolve_with: #{Rails.application.config.assets.resolve_with.inspect}"
    Rails.logger.info "assets.digest: #{Rails.application.config.assets.digest.inspect}"
    Rails.logger.info "Manifest path: #{Rails.application.assets_manifest&.path}"
    Rails.logger.info '=== END ==='
  end
end
# rubocop:enable Rails/UnknownEnv
