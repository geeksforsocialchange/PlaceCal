# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PlaceCal
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.active_job.queue_adapter = :delayed_job

    config.time_zone = 'Europe/London'

    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
    config.autoload_paths += Dir[Rails.root.join('app', 'api', '*')]

    # Configure Zeitwerk to properly namespace Admin components
    # ViewComponent treats subdirectories as sidecar roots, but we want admin/
    # to be a namespace so Admin::AlertComponent lives in admin/alert_component.rb
    initializer 'placecal.admin_components_namespace', before: :set_autoload_paths do
      # Define Admin module if not already defined (it will be, via controllers)
      Object.const_set(:Admin, Module.new) unless Object.const_defined?(:Admin)
      Rails.autoloaders.main.push_dir(
        Rails.root.join('app/components/admin'),
        namespace: Admin
      )
    end

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        # API requests
        resource '/api/*', headers: :any, methods: %i[get options]
        # Embeddable widget thing - update with new stack
        resource '/widget.js', headers: :any, methods: %i[get options]
      end
    end
  end
end
