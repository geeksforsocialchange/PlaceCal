# frozen_string_literal: true

require "spec_helper"
require "open3"
require "tmpdir"

# The generator that points core's bundle at an extension checkout (#3368 WP
# 5.2). Both theme repos shipped one of these and they disagreed: one dropped
# the whole :extensions group, so its CI never loaded the other extension. The
# semantics here are the surviving ones, and this is what pins them: only the
# named gems move to a path, everything else stays as core pins it.
RSpec.describe "bin/extension-dev-gemfile" do
  SCRIPT = File.expand_path("../../bin/extension-dev-gemfile", __dir__)

  let(:core) { Dir.mktmpdir }

  let(:gemfile) do
    <<~RUBY
      # frozen_string_literal: true
      source 'https://rubygems.org'

      gem 'rails'

      group :extensions do
        gem 'placecal-theme-mossley', github: 'geeksforsocialchange/placecal-theme-mossley', tag: 'v0.1.1'
        gem 'placecal-theme-transdimension', github: 'geeksforsocialchange/placecal-theme-transdimension', tag: 'v0.3.11'
      end
    RUBY
  end

  before { File.write(File.join(core, "Gemfile"), gemfile) }

  after { FileUtils.remove_entry(core) }

  def run(*pairs)
    Open3.capture3("ruby", SCRIPT, "--core", core, *pairs)
  end

  def generated
    File.read(File.join(core, "Gemfile.extensions-dev"))
  end

  # Evaluate the generated Gemfile the way Bundler would, recording what it
  # asks for. Anything less than this tests the string, not the behaviour.
  def resolved_gems
    recorder = Class.new do
      attr_reader :gems

      def initialize = @gems = {}
      def source(*) = nil
      def group(*) = yield
      def gem(name, *_args, **options) = @gems[name] = options
    end.new

    path = File.join(core, "Gemfile.extensions-dev")
    recorder.instance_eval(File.read(path), path, 1)
    recorder.gems
  end

  it "writes the generated Gemfile beside core's own" do
    _out, _err, status = run("placecal-theme-transdimension=../placecal-theme-transdimension")

    expect(status).to be_success
    expect(File.exist?(File.join(core, "Gemfile.extensions-dev"))).to be(true)
    expect(generated).to include("do not commit")
  end

  it "takes the named extension from the path and leaves the rest at their tags" do
    run("placecal-theme-transdimension=../placecal-theme-transdimension")

    expect(resolved_gems["placecal-theme-transdimension"]).to eq(path: "../placecal-theme-transdimension")
    expect(resolved_gems["placecal-theme-mossley"]).to include(tag: "v0.1.1")
  end

  # One boot loading two engines is a property core has to keep working, so a
  # generator that dropped the sibling extension would hide a regression in it.
  it "keeps every other gem in core's Gemfile" do
    run("placecal-theme-mossley=../placecal-theme-mossley")

    expect(resolved_gems.keys).to contain_exactly(
      "rails", "placecal-theme-mossley", "placecal-theme-transdimension"
    )
  end

  it "takes more than one extension from a path at once" do
    run("placecal-theme-mossley=../m", "placecal-theme-transdimension=../td")

    expect(resolved_gems["placecal-theme-mossley"]).to eq(path: "../m")
    expect(resolved_gems["placecal-theme-transdimension"]).to eq(path: "../td")
  end

  it "reads core's Gemfile at evaluation time, so it does not go stale" do
    run("placecal-theme-transdimension=../placecal-theme-transdimension")
    File.write(File.join(core, "Gemfile"), "#{gemfile}\ngem 'added-later'\n")

    expect(resolved_gems).to have_key("added-later")
  end

  describe "when it cannot do what was asked" do
    it "refuses a gem core's Gemfile does not have" do
      _out, err, status = run("placecal-theme-nowhere=../nowhere")

      expect(status).not_to be_success
      expect(err).to include("placecal-theme-nowhere is not in")
    end

    it "refuses an argument that is not <gem>=<path>" do
      _out, err, status = run("placecal-theme-mossley")

      expect(status).not_to be_success
      expect(err).to include("is not <gem>=<path>")
    end

    it "refuses to run with no extension named" do
      _out, err, status = run

      expect(status).not_to be_success
      expect(err).to include("name at least one extension")
    end

    it "refuses a --core without a Gemfile" do
      FileUtils.rm(File.join(core, "Gemfile"))
      _out, err, status = run("placecal-theme-mossley=../m")

      expect(status).not_to be_success
      expect(err).to include("no Gemfile at")
    end
  end
end
