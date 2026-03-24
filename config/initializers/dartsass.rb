# frozen_string_literal: true

# Configure Dart Sass build entry points.
# Each key is a source file (relative to app/assets/stylesheets/),
# each value is the output file (relative to app/assets/builds/).

Rails.application.config.dartsass.builds = {
  'application.scss' => 'application.css',
  'home.scss' => 'home.css',
  'themes/blue.scss' => 'themes/blue.css',
  'themes/green.scss' => 'themes/green.css',
  'themes/orange.scss' => 'themes/orange.css',
  'themes/pink.scss' => 'themes/pink.css',
  'themes/custom/mossley.scss' => 'themes/custom/mossley.css'
}

# Silence @import deprecation warnings — migration to @use/@forward is a separate task.
Rails.application.config.dartsass.build_options = [
  '--style=compressed',
  '--no-source-map',
  '--silence-deprecation=import'
]
