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

  # Debug at request time - intercept javascript_importmap_tags
  module ImportmapRequestDebug
    def javascript_importmap_tags(entry_point = 'application', shim: true)
      # Log what path_to_asset returns for a controller
      test_path = path_to_asset('controllers/dropdown_controller.js')
      Rails.logger.info '=== IMPORTMAP REQUEST DEBUG ==='
      Rails.logger.info "path_to_asset('controllers/dropdown_controller.js') = #{test_path}"
      Rails.logger.info "compute_asset_path result: #{compute_asset_path('controllers/dropdown_controller.js')}"
      Rails.logger.info '=== END REQUEST DEBUG ==='
      super
    end
  end

  ActiveSupport.on_load(:action_view) do
    prepend ImportmapRequestDebug
  end
end
# rubocop:enable Rails/UnknownEnv
