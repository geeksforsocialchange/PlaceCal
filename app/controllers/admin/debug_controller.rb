# frozen_string_literal: true

# Temporary debug controller for diagnosing importmap asset resolution
# Remove this file after fixing the staging importmap issue

module Admin
  class DebugController < ApplicationController
    skip_before_action :authenticate_user!
    layout 'admin/application'

    def importmap
      @debug_info = {
        path_to_asset: helpers.path_to_asset('controllers/dropdown_controller.js'),
        compute_asset_path: helpers.compute_asset_path('controllers/dropdown_controller.js'),
        resolve_with: Rails.application.config.assets.resolve_with,
        digest: Rails.application.config.assets.digest,
        manifest_path: Rails.application.assets_manifest&.path,
        importmap_json: Rails.application.importmap.to_json(resolver: helpers)[0..1000]
      }
    end
  end
end
