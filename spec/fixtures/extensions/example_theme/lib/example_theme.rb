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

# The two-line host guard every extension keeps (see doc/extensions.md): an
# older core has no PlaceCal::Extension, and the engine below would fail with a
# bare NameError from the middle of a class body instead of saying what is
# missing.
abort("example_theme needs a PlaceCal with PlaceCal::Extension; see doc/extensions.md.") unless defined?(PlaceCal::Extension) # rubocop:disable Rails/Exit

require_relative "example_theme/engine"
