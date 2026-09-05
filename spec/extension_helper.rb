# frozen_string_literal: true

module PlaceCal
  # Boots core's Rails application with one extension engine loaded, the way
  # Bundler would load the gem in a real installation (#3368 WP 5.2).
  #
  # Every extension needs the same rails_helper, and all of it is core
  # knowledge: where core is, what order to require it in, which of core's spec
  # support files and factories to reuse, and how core configures RSpec. An
  # extension's spec/rails_helper.rb is therefore four lines:
  #
  #   require "spec_helper"
  #
  #   PLACECAL_CORE = Pathname(ENV.fetch("PLACECAL_CORE_PATH", File.expand_path("../../PlaceCal", __dir__))).expand_path
  #   require PLACECAL_CORE.join("spec/extension_helper").to_s
  #   PlaceCal::ExtensionSpec.boot!(engine: "transdimension")
  #
  # Pass `system_specs: true` to add the per-example configuration a system
  # spec needs (DatabaseCleaner and a headless Chrome driver). It is opt-in
  # because an extension with no system specs should not need a browser in CI.
  #
  # The signature is the compatibility surface. An extension pinned to a core
  # tag may run its suite against core's main, so `boot!` keeps its keywords
  # stable and core's own fixture-engine specs exercise it.
  module ExtensionSpec
    # Core's checkout, taken from this file rather than from the caller: an
    # extension found this file, so it already knows where core is.
    CORE_ROOT = Pathname(__dir__).parent.expand_path

    class << self
      # @param engine [String, Symbol] the extension's module name in snake
      #   case, which is both `lib/<engine>.rb` and `<Engine>::Engine`
      # @param root [String, Pathname, nil] the extension checkout under test;
      #   defaults to the parent of the calling file's directory, which is the
      #   extension root when the caller is its spec/rails_helper.rb
      # @param system_specs [Boolean] configure system specs as well
      def boot!(engine:, root: nil, system_specs: false)
        engine = engine.to_s
        root = Pathname(root || default_root(caller_locations(1, 1))).expand_path

        boot_rails!(engine, root)
        assert_working_tree!(engine, root)
        configure_rspec!(system_specs: system_specs)
      end

      # @return [Pathname]
      def core_root
        CORE_ROOT
      end

      private

      def default_root(locations)
        path = locations&.first&.absolute_path || locations&.first&.path
        raise ArgumentError, "PlaceCal::ExtensionSpec.boot! could not work out the extension root; pass root:" if path.nil?

        Pathname(path).dirname.parent
      end

      # Core's application, then the engine, then core's environment: the
      # engine has to be required before the environment initialises so its
      # initializers run and the theme is registered.
      def boot_rails!(engine, root)
        ENV["RAILS_ENV"] ||= "test"

        raise "PlaceCal core not found at #{CORE_ROOT}; set PLACECAL_CORE_PATH" unless CORE_ROOT.join("config/application.rb").exist?

        require CORE_ROOT.join("config/application").to_s
        # Bundler has already required the engine when the extension is in
        # core's bundle, which is the supported way to run. An extension that
        # is not in the Gemfile yet still boots, from its own lib.
        $LOAD_PATH.unshift(root.join("lib").to_s) unless $LOAD_PATH.include?(root.join("lib").to_s)
        require engine
        require CORE_ROOT.join("config/environment").to_s

        abort("The Rails environment is running in production mode!") if Rails.env.production?
      end

      # Core's Gemfile pins an extension to a git tag. If the run picks up that
      # copy instead of the working tree (wrong BUNDLE_GEMFILE, or a generated
      # dev Gemfile whose path entry is stale), every example passes against
      # code nobody is editing.
      def assert_working_tree!(engine, root)
        engine_root = engine_class(engine).root.expand_path
        return if engine_root == root

        abort(
          "Specs are running against the installed engine at #{engine_root}, " \
          "not this working tree at #{root}. Point BUNDLE_GEMFILE at a Gemfile whose " \
          "#{gem_name(root, engine)} entry uses `path:` (see README \"Development\")."
        )
      end

      def engine_class(engine)
        Object.const_get("#{engine.camelize}::Engine")
      end

      # The gem name is what a Gemfile entry is called, and it is not always
      # the engine's module name (placecal-theme-mossley holds Mossley).
      def gem_name(root, engine)
        root.glob("*.gemspec").first&.basename(".gemspec")&.to_s || engine
      end

      def configure_rspec!(system_specs:)
        require "rspec/rails"
        require "capybara/rspec"
        require "pundit/rspec"

        # Core's spec support files (helpers, VCR, shared contexts) are
        # reusable here, and so are its factories.
        CORE_ROOT.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |file| require file.to_s }
        FactoryBot.definition_file_paths = [CORE_ROOT.join("spec/factories")]
        FactoryBot.reload

        begin
          ActiveRecord::Migration.maintain_test_schema!
        rescue ActiveRecord::PendingMigrationError => e
          abort e.to_s.strip
        end

        # Core leaves config.action_view.raise_on_missing_translations commented
        # out in its test environment, so a key deleted out from under a view
        # would render as a humanised placeholder and every example would still
        # pass. Raise instead: the render specs then catch a missing key at the
        # point of use, including keys built at runtime.
        I18n.exception_handler = ->(exception, *_args) { raise exception }

        RSpec.configure do |config|
          config.fixture_paths = [CORE_ROOT.join("spec/fixtures")]
          config.use_transactional_fixtures = true
          config.infer_spec_type_from_file_location!
          config.filter_rails_from_backtrace!

          config.include FactoryBot::Syntax::Methods
          # Core's helper for rendering a Phlex view or component on its own.
          config.include PhlexTestHelper, type: :component
          config.include Devise::Test::IntegrationHelpers, type: :request

          # Core freezes time in its own suite; match it so shared factories
          # behave the same way here.
          config.before { Timecop.freeze(Time.zone.local(2022, 11, 8)) }
          config.after { Timecop.return }
        end

        configure_system_specs! if system_specs
      end

      # System specs, the same way core drives its own (spec/rails_helper.rb
      # there). Core's spec/support already gives us Capybara, Selenium and the
      # axe-rspec matcher; what does not come with the support files is the
      # per-example configuration, because that lives in core's RSpec.configure
      # block.
      #
      # A system spec runs the browser in another thread, so an open
      # transaction would hide the fixtures from it. Delete instead.
      def configure_system_specs!
        RSpec.configure do |config|
          config.before(:each, type: :system) do
            self.use_transactional_tests = false
            DatabaseCleaner.strategy = :deletion
            DatabaseCleaner.start
            driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
          end

          config.after(:each, type: :system) { DatabaseCleaner.clean }
        end
      end
    end
  end
end
