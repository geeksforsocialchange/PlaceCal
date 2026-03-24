# frozen_string_literal: true

# Remove app/assets/stylesheets from Sprockets' asset paths.
#
# SCSS compilation is handled entirely by dartsass-rails, which reads
# from app/assets/stylesheets/ and outputs pre-built CSS into
# app/assets/builds/. Sprockets must not see the .scss source files
# because it tries to process them with the removed 'sass' gem.
# The pre-built CSS in app/assets/builds/ is already in Sprockets'
# path and linked via the manifest.
Rails.application.config.assets.configure do |env|
  stylesheets = Rails.root.join('app/assets/stylesheets').to_s
  env.clear_paths
  Rails.application.config.assets.paths.each do |path|
    env.append_path(path.to_s) unless path.to_s == stylesheets
  end
end
