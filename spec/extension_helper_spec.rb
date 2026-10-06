# frozen_string_literal: true

require "rails_helper"
require_relative "extension_helper"

# The boot helper an extension's spec/rails_helper.rb calls (#3368 WP 5.2).
#
# `boot!` itself requires core's environment and reconfigures RSpec globally, so
# it cannot run inside a suite that is already booted. What is unit-testable is
# everything it works out before it touches Rails: where core is, where the
# extension is, which constant to assert against and what to call the gem in the
# abort message. The end-to-end proof is running an extension's own suite
# through it.
RSpec.describe PlaceCal::ExtensionSpec do
  let(:fixture_engine) { Rails.root.join("spec/fixtures/extensions/example_theme") }

  it "finds core from its own location, not from the caller" do
    expect(described_class.core_root).to eq(Rails.root)
    expect(described_class::CORE_ROOT.join("config/application.rb")).to exist
  end

  describe "the extension root" do
    it "defaults to the parent of the calling file's directory" do
      caller_in_spec_dir = [instance_double(Thread::Backtrace::Location,
                                            absolute_path: fixture_engine.join("spec/rails_helper.rb").to_s)]

      expect(described_class.send(:default_root, caller_in_spec_dir)).to eq(fixture_engine)
    end

    it "says so when it cannot work one out" do
      expect { described_class.send(:default_root, []) }
        .to raise_error(ArgumentError, /could not work out the extension root; pass root:/)
    end
  end

  describe "the working-tree assertion" do
    it "passes when the loaded engine is the checkout under test" do
      expect { described_class.send(:assert_working_tree!, "example_theme", fixture_engine) }.not_to raise_error
    end

    it "aborts naming the gem when the loaded engine is somewhere else" do
      expect { described_class.send(:assert_working_tree!, "example_theme", Rails.root.join("elsewhere")) }
        .to raise_error(SystemExit)
    end

    it "resolves the engine constant from the engine name" do
      expect(described_class.send(:engine_class, "example_theme")).to eq(ExampleTheme::Engine)
    end
  end

  # The gem name is what a Gemfile entry is called, which is not the engine's
  # module name: placecal-theme-mossley holds Mossley.
  describe "the gem name in the abort message" do
    it "comes from the extension's gemspec" do
      Dir.mktmpdir do |dir|
        FileUtils.touch(File.join(dir, "placecal-theme-mossley.gemspec"))

        expect(described_class.send(:gem_name, Pathname(dir), "mossley")).to eq("placecal-theme-mossley")
      end
    end

    it "falls back to the engine name when there is no gemspec" do
      Dir.mktmpdir do |dir|
        expect(described_class.send(:gem_name, Pathname(dir), "mossley")).to eq("mossley")
      end
    end
  end

  describe "the system-spec option" do
    # Everything configure_rspec! does to the running suite is stubbed: the
    # question is only which branch it takes.
    before do
      allow(described_class).to receive(:require)
      allow(described_class).to receive(:configure_system_specs!)
      allow(RSpec).to receive(:configure)
      allow(FactoryBot).to receive_messages(definition_file_paths: nil, reload: nil)
      allow(ActiveRecord::Migration).to receive(:maintain_test_schema!)
      allow(I18n).to receive(:exception_handler=)
    end

    it "is off by default, so an extension with no system specs needs no browser" do
      described_class.send(:configure_rspec!, system_specs: false)

      expect(described_class).not_to have_received(:configure_system_specs!)
    end

    it "configures DatabaseCleaner and a headless Chrome driver when asked" do
      described_class.send(:configure_rspec!, system_specs: true)

      expect(described_class).to have_received(:configure_system_specs!)
    end
  end
end
