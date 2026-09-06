# frozen_string_literal: true

require "rails_helper"

# The shared engine infrastructure extensions used to copy (#3368 WP 5.2).
# The fixture engine under spec/fixtures/extensions/example_theme includes it,
# so these examples are run against the same code a real extension boots.
RSpec.describe PlaceCal::Extension do
  # A namespace with the Phlex constants an extension declares in its
  # lib/<name>.rb, and a class that takes only the DSL. Nothing here is a
  # Rails::Engine: defining one at runtime would add a railtie with no root to
  # every later Rails::Engine.subclasses walk in this process.
  module ExtensionDouble
    module Views; end

    module Components; end

    class Engine
      extend PlaceCal::Extension::ClassMethods
    end
  end

  after { ExtensionDouble::Engine.required_settings([]) }

  describe "the engine it can be included into" do
    it "is a Rails engine, and says so when it is not" do
      not_an_engine = Class.new

      expect { not_an_engine.include(described_class) }
        .to raise_error(ArgumentError, /must be a Rails::Engine to include PlaceCal::Extension/)
    end

    it "derives the extension name from the engine's own namespace" do
      expect(ExampleTheme::Engine.extension_namespace).to eq(ExampleTheme)
      expect(ExampleTheme::Engine.extension_name).to eq("example_theme")
      expect(ExtensionDouble::Engine.extension_name).to eq("extension_double")
    end

    it "names its initializers after the extension" do
      names = ExampleTheme::Engine.initializers.map(&:name)

      expect(names).to include("example_theme.phlex_namespaces", "example_theme.register_theme")
    end
  end

  describe "Zeitwerk namespaces" do
    it "pushes the engine's view and component directories under its own namespaces" do
      root = ExampleTheme::Engine.root

      expect(ExampleTheme::Engine.phlex_dirs(root)).to contain_exactly(
        [root.join("app/views/example_theme"), ExampleTheme::Views],
        [root.join("app/components/example_theme"), ExampleTheme::Components]
      )
    end

    it "pushed them at boot, so the engine's classes autoload" do
      expect(Rails.autoloaders.main.dirs(namespaces: true)).to include(
        ExampleTheme::Engine.root.join("app/views/example_theme").to_s => ExampleTheme::Views,
        ExampleTheme::Engine.root.join("app/components/example_theme").to_s => ExampleTheme::Components
      )
    end

    # Mossley builds its homepage entirely from core's components and ships no
    # app/components at all. Pushing a directory that is not there is a
    # Zeitwerk error at boot, so only what the extension ships is pushed.
    it "skips a directory the extension does not ship" do
      views_only = Dir.mktmpdir
      FileUtils.mkdir_p(File.join(views_only, "app/views/extension_double"))

      expect(ExtensionDouble::Engine.phlex_dirs(Pathname(views_only)))
        .to eq([[Pathname(views_only).join("app/views/extension_double"), ExtensionDouble::Views]])
    ensure
      FileUtils.remove_entry(views_only)
    end
  end

  describe "the host guard" do
    it "names the missing registry rather than raising NoMethodError" do
      expect { ExampleTheme::Engine.verify_host!(nil) }.to raise_error(
        PlaceCal::Extension::UnsupportedHost,
        "PlaceCal::Extensions.register_theme is not available: this theme needs a PlaceCal " \
        'with the extension theme registry (see "Minimum core" in the engine README).'
      )
    end

    it "passes against this core's registry" do
      expect(ExampleTheme::Engine.host_registry).to eq(PlaceCal::Extensions)
      expect { ExampleTheme::Engine.verify_host! }.not_to raise_error
    end
  end

  describe "the theme guard" do
    it "names every setting the host is missing" do
      ExtensionDouble::Engine.required_settings %i[stylesheet no_such_setting another_missing_one]

      expect { ExtensionDouble::Engine.verify_theme!(PlaceCal::Theme.new(:double)) }.to raise_error(
        PlaceCal::Extension::UnsupportedHost,
        "PlaceCal::Theme does not support no_such_setting, another_missing_one: this theme needs a newer " \
        'PlaceCal (see "Minimum core" in the engine README).'
      )
    end

    it "passes when the host supports every declared setting" do
      expect { ExampleTheme::Engine.verify_theme!(PlaceCal::Theme.new(:double)) }.not_to raise_error
    end
  end

  describe "the declared settings list" do
    it "reads back what the engine declared, as symbols" do
      ExtensionDouble::Engine.required_settings %w[stylesheet map_style]

      expect(ExtensionDouble::Engine.required_settings).to eq(%i[stylesheet map_style])
    end

    it "is empty for an engine that declares none" do
      expect(ExtensionDouble::Engine.required_settings).to eq([])
    end

    # The guard is only worth having if it names settings core really has.
    it "is a list of settings PlaceCal::Theme supports" do
      theme = PlaceCal::Theme.new(:double)

      expect(ExampleTheme::Engine.required_settings.reject { |setting| theme.respond_to?(setting) }).to be_empty
    end
  end

  describe "theme registration" do
    it "registers the declared theme at boot" do
      expect(ExampleTheme::Engine.theme_name).to eq(:example_theme)
      expect(PlaceCal::Extensions.find_theme("example_theme")).to be_a(PlaceCal::Theme)
    end

    it "applies the declared block to a theme, so a contract spec can run it standalone" do
      theme = ExampleTheme::Engine.configure_theme(PlaceCal::Theme.new(:throwaway))

      expect(theme.stylesheet).to eq("example_theme/theme")
      expect(theme.homepage_view).to eq("ExampleTheme::Views::Home")
      expect(theme.event_filter_style).to eq(:day_strip)
      expect(theme.pages.keys).to eq(%w[proof fixture-content])
    end

    it "runs the theme guard before the block" do
      ExtensionDouble::Engine.required_settings %i[no_such_setting]
      configured = false
      ExtensionDouble::Engine.theme(:double) { configured = true }

      expect { ExtensionDouble::Engine.configure_theme(PlaceCal::Theme.new(:double)) }
        .to raise_error(PlaceCal::Extension::UnsupportedHost)
      expect(configured).to be(false)
    end

    it "says so when an engine includes the module but declares no theme" do
      no_theme = Class.new { extend PlaceCal::Extension::ClassMethods }
      stub_const("ExtensionDouble::NoTheme", no_theme)

      expect { no_theme.register_theme! }
        .to raise_error(ArgumentError, /includes PlaceCal::Extension but declares no theme/)
    end
  end
end
