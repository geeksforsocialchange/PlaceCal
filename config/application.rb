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
    config.active_job.queue_adapter = :delayed_job

    config.time_zone = 'Europe/London'

    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
    config.autoload_paths += Dir[Rails.root.join('app', 'api', '*')]

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '/partners/*', headers: :any, methods: %i[get options]
        resource '/widget.js', headers: :any, methods: %i[get options]
      end
    end
  end
end
