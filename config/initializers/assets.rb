# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'pdfs')
Rails.application.config.assets.paths << Rails.root.join('app', 'assets', 'fonts')
Rails.application.config.assets.paths << Rails.root.join('node_modules')
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

# Bypass segfault in sassc 2.* + sprockets 4: https://github.com/rails/sprockets/issues/581#issuecomment-486984663
Rails.application.config.assets.configure do |env|
  env.export_concurrent = false
end

Rails.application.config.assets.precompile += %w[
  print.css
  admin.css
  sites/hulme.css
  sites/moss-side.css
  sites/rusholme.css
  sites/moston.css
  sites/mossley.css
]
