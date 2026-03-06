# frozen_string_literal: true

# Configure dartsass-rails SCSS entry points.
# Each entry is compiled to app/assets/builds/ for Propshaft to serve.
Rails.application.config.dartsass.builds = {
  'application.scss' => 'application.css',
  'home.scss' => 'home.css',
  'print.scss' => 'print.css',
  'themes/blue.scss' => 'themes/blue.css',
  'themes/green.scss' => 'themes/green.css',
  'themes/orange.scss' => 'themes/orange.css',
  'themes/pink.scss' => 'themes/pink.css',
  'themes/custom/mossley.scss' => 'themes/custom/mossley.css'
}

# Silence @import deprecation — these SCSS files are being incrementally
# migrated to Tailwind. Converting @import → @use/@forward for temporary
# code is not worthwhile. Remove this when dartsass-rails is removed.
Rails.application.config.dartsass.build_options = [
  '--style=compressed',
  '--no-source-map',
  '--silence-deprecation=import'
]
