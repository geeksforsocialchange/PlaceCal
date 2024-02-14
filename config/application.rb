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
