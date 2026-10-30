# frozen_string_literal: true

require_relative 'boot'
require 'rails/all'

# The extension contract has to exist before Bundler requires the extension
# engines: an engine's class body calls `include PlaceCal::Extension` while it
# is being required, and its initializers register into PlaceCal::Extensions at
# boot. lib/ is not autoloaded, so it is required here (extension.rb requires
# the registry itself).
require_relative '../lib/placecal/extension'
require_relative '../lib/placecal/svg_sandbox_headers'

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

    # Partial matches, filtered from logs, AppSignal and #inspect. Set here because delayed_job loads
    # ActiveRecord during Bundler.require, which copies this list into filter_attributes before initializers run.
    config.filter_parameters += %i[passw email secret token _key crypt salt certificate otp ssn cvv cvc]

    config.time_zone = 'Europe/London'

    # Cloudflare's edges (https://www.cloudflare.com/ips) count as proxies, so remote_ip is the visitor
    config.action_dispatch.trusted_proxies = ActionDispatch::RemoteIp::TRUSTED_PROXIES + %w[
      173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 141.101.64.0/18 108.162.192.0/18
      190.93.240.0/20 188.114.96.0/20 197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13
      104.24.0.0/14 172.64.0.0/13 131.0.72.0/22
      2400:cb00::/32 2606:4700::/32 2803:f800::/32 2405:b500::/32 2405:8100::/32 2a06:98c0::/29 2c0f:f248::/32
    ].map { |range| IPAddr.new(range) }

    config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
    config.autoload_paths += Dir[Rails.root.join('app/api/*')]

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

    config.middleware.insert_before 0, PlaceCal::SvgSandboxHeaders

    # Lookbook component previews (http://lvh.me:3000/lookbook); the gem loads in development and test only
    if defined?(Lookbook)
      config.lookbook.project_name = 'PlaceCal'
      config.lookbook.preview_paths = ['spec/components/previews']
      config.lookbook.page_paths = ['spec/components/docs']
      config.lookbook.preview_layout = 'lookbook_preview'
      # Embedded previews (overview and component pages) show the component only, no code panels
      config.lookbook.preview_embed_panels = []
      # Previews mirror app/components, so two can share a name (Sites::Footer, Directory::Footer)
      config.lookbook.preview_url_param = :named_uuid
      Lookbook.add_panel(:theming, 'lookbook/panels/theming', label: 'Theming',
                                                              disabled: ->(data) { PlaceCal::Theming.scope_of("Components::#{data.preview.preview_class_name.delete_suffix('Preview')}").nil? })
      # Themes register in initializers, so the dropdown can only be built after them
      config.after_initialize do
        config.lookbook.preview_display_options = { theme: PlaceCal::Extensions.theme_names }
        Rack::MiniProfiler.config.skip_paths << '/lookbook' if defined?(Rack::MiniProfiler)
      end
    end
  end
end
