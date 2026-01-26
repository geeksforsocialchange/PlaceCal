# frozen_string_literal: true

Rails.application.config.view_component.generate.sidecar = true
Rails.application.config.view_component.preview_paths << Rails.root.join('app/components/previews')
Rails.application.config.view_component.default_preview_layout = 'component_preview'

# NOTE: Admin::* components are namespaced via Zeitwerk configuration in
# config/application.rb using push_dir with namespace: Admin
