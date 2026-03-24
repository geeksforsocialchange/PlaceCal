# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
Rails.application.config.assets.paths << Rails.root.join('app', 'javascript')
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'pdfs')
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
Rails.application.config.assets.paths << Rails.root.join('node_modules')
Rails.application.config.assets.paths << Rails.root.join('app', 'components')
# So we can use SvgImagesHelper for logos etc
Rails.application.config.assets.paths << Rails.root.join(Rails.public_path, 'uploads')
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w[
  es-module-shims.js
]

# NOTE: admin.css removed - admin now uses admin_tailwind.css built by Tailwind CLI

# NOTE: admin_tailwind.css is pre-built by Tailwind CLI into app/assets/builds/
# and picked up automatically by Rails - no need to add to precompile list
