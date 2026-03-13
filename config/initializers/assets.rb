# frozen_string_literal: true

# Propshaft auto-discovers app/assets/* subdirectories.
# Add any extra asset paths here.
Rails.application.config.assets.paths << Rails.root.join('vendor/assets/javascripts')
