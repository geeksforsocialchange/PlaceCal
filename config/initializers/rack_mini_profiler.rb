# frozen_string_literal: true

# Development only (Gemfile); top-left covered the site logo and navigation
Rack::MiniProfiler.config.position = 'top-right' if defined?(Rack::MiniProfiler)
