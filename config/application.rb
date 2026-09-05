# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'

# The extension contract has to exist before Bundler requires the extension
# engines: an engine's class body calls `include PlaceCal::Extension` while it
# is being required, and its initializers register into PlaceCal::Extensions at
# boot. lib/ is not autoloaded, so it is required here (extension.rb requires
# the registry itself).
require_relative '../lib/placecal/extension'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
# :extensions holds installation-specific engines (see the Gemfile block and
# doc/extensions.md); it is not an environment group, so it is named here.
Bundler.require(*Rails.groups, :extensions)

module PlaceCal
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    config.active_job.queue_adapter = :delayed_job

    config.time_zone = 'Europe/London'

    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
    config.autoload_paths += Dir[Rails.root.join('app', 'api', '*')]

    # Phlex views: app/views/ (Views::), components: app/components/ (Components::)
    # See config/initializers/phlex.rb for Zeitwerk namespace configuration

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
