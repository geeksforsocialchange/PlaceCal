# frozen_string_literal: true

# Configure dartsass-rails SCSS entry points.
# Each entry is compiled to app/assets/builds/ for Propshaft to serve.
#
# These SCSS files are being incrementally migrated to Tailwind CSS.
# When all files are converted, dartsass-rails can be removed entirely.
# See app/assets/stylesheets/README.md for the full picture.
Rails.application.config.dartsass.builds = {
  # Loaded on every public page (globals, base styles, components)
  'application.scss' => 'application.css',

  # Default site (placecal.org) homepage styles — loaded via Site#stylesheet_link
  'home.scss' => 'home.css',

  # Print media stylesheet
  'print.scss' => 'print.css',

  # Partner colour themes — loaded via Site#stylesheet_link
  'themes/blue.scss' => 'themes/blue.css',
  'themes/green.scss' => 'themes/green.css',
  'themes/orange.scss' => 'themes/orange.css',
  'themes/pink.scss' => 'themes/pink.css',

  # Full custom theme (Mossley) — loaded via Site#stylesheet_link
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
