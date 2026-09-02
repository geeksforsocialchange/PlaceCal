# frozen_string_literal: true

# Test-only fixture extension (WP 0.4 of #3368). Proves that a PlaceCal
# extension engine can autoload its own Phlex namespaces, render inside the
# core layout, have its committed CSS served by Propshaft and load its own
# locale file, all without editing any core config file.
#
# It is required from spec/rails_helper.rb before the Rails environment
# boots, exactly as a real extension gem would be required by Bundler.
module ExampleTheme
  # Phlex namespaces. Core keeps Views and Components; an extension owns
  # <Extension>::Views and <Extension>::Components.
  module Views; end

  module Components
    extend Phlex::Kit
  end
end

require_relative "example_theme/engine"
