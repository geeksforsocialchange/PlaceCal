# frozen_string_literal: true

# Prevent Sprockets from trying to compile .scss files.
#
# SCSS compilation is handled entirely by dartsass-rails, which outputs
# pre-built CSS into app/assets/builds/. However, Sprockets auto-registers
# a text/scss -> text/css transformer (ScsscProcessor) that tries to load
# the removed 'sass' gem when it encounters .scss source files in
# app/assets/stylesheets/. Override it with a no-op so Sprockets skips
# SCSS processing entirely.
Rails.application.config.after_initialize do
  noop = ->(input) { { data: input[:data] } }
  Sprockets.register_transformer 'text/scss', 'text/css', noop
end
