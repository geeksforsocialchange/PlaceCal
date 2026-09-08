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
  # A local, not a top-level constant: check_extension_tree_spec.rb defines its
  # own SCRIPT, and RSpec example groups share Object for constants.
  let(:script) { File.expand_path("../../bin/extension-dev-gemfile", __dir__) }
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
    Open3.capture3("ruby", script, "--core", core, *pairs)
  end

  def generated
    File.read(File.join(core, "Gemfile.extensions-dev"))
  end

  # Evaluate the generated Gemfile the way Bundler would, recording what it
  # asks for. Anything less than this tests the string, not the behaviour.
  def recorder_result
    recorder = Class.new do
      attr_reader :gems, :groups

      def initialize
        @gems = {}
        @groups = {}
        @current = []
      end

      def source(*) = nil

      def group(*names)
        @current = names
        yield
      ensure
        @current = []
      end

      def gem(name, *_args, **options)
        @gems[name] = options
        @groups[name] = @current
      end
    end.new

    path = File.join(core, "Gemfile.extensions-dev")
    recorder.instance_eval(File.read(path), path, 1)
    recorder
  end

  def resolved_gems = recorder_result.gems
  def resolved_groups = recorder_result.groups

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

  # bin/check-extension-tree finds what to check by the :extensions group, so a
  # path entry outside it leaves the gem under test unchecked while its
  # sibling, still at its tag, passes and the run reports green.
  it "puts the path entry back in the :extensions group" do
    run("placecal-theme-transdimension=../placecal-theme-transdimension")

    expect(resolved_groups["placecal-theme-transdimension"]).to eq([:extensions])
    expect(resolved_groups["placecal-theme-mossley"]).to eq([:extensions])
    expect(resolved_groups["rails"]).to eq([])
  end

  # doc/extensions.md prints the entry wrapped over three lines, and a real
  # Gemfile may be reformatted that way. A one-line strip left the orphaned
  # github:/tag: lines behind and the generated Gemfile did not parse.
  it "strips an entry that wraps over several lines" do
    File.write(File.join(core, "Gemfile"), <<~RUBY)
      source 'https://rubygems.org'

      gem 'rails'

      group :extensions do
        gem 'placecal-theme-transdimension',
            github: 'geeksforsocialchange/placecal-theme-transdimension',
            tag: 'v0.3.11'
      end
    RUBY

    run("placecal-theme-transdimension=../td")

    expect(resolved_gems["placecal-theme-transdimension"]).to eq(path: "../td")
    expect(resolved_gems.keys).to contain_exactly("rails", "placecal-theme-transdimension")
  end

  # The path comes off a command line, so it is not the generator's to trust.
  it "escapes the name and the path it writes" do
    run("placecal-theme-mossley=../it's here")

    expect(resolved_gems["placecal-theme-mossley"]).to eq(path: "../it's here")
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

  describe "the lockfile" do
    let(:lockfile) { File.join(core, "Gemfile.extensions-dev.lock") }

    let(:core_lock) do
      <<~LOCK
        GIT
          remote: https://github.com/geeksforsocialchange/placecal-theme-transdimension.git
          revision: 24ad592c109c926c3369394b1c1098b3a27159b4
          tag: v0.3.15
          specs:
            placecal-theme-transdimension (0.3.15)
              rails (>= 8.0)

        GEM
          remote: https://rubygems.org/
          specs:
            json (2.21.2)
            rails (8.1.0)

        DEPENDENCIES
          placecal-theme-transdimension!
          rails
      LOCK
    end

    # A checkout beside core with the gemspec the seed reads the version and
    # dependencies from.
    def write_checkout
      dir = File.join(core, "theme")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "placecal-theme-transdimension.gemspec"), <<~GEMSPEC)
        Gem::Specification.new do |spec|
          spec.name = "placecal-theme-transdimension"
          spec.version = "0.4.0"
          spec.summary = "test"
          spec.authors = ["test"]
          spec.add_dependency "rails", ">= 8.0"
          spec.add_dependency "phlex", "~> 2.0"
        end
      GEMSPEC
    end

    before { write_checkout }

    it "is seeded from core's Gemfile.lock with the checkout as a path source, so nothing else resolves afresh" do
      File.write(File.join(core, "Gemfile.lock"), core_lock)
      _out, err, status = run("placecal-theme-transdimension=theme")

      expect(status).to be_success, err
      seeded = File.read(lockfile)
      expect(seeded).to include("json (2.21.2)")
      expect(seeded).not_to include("GIT")
      expect(seeded).to start_with(<<~SECTION)
        PATH
          remote: theme
          specs:
            placecal-theme-transdimension (0.4.0)
              phlex (~> 2.0)
              rails (>= 8.0)

      SECTION
    end

    it "leaves an existing lockfile alone" do
      File.write(File.join(core, "Gemfile.lock"), core_lock)
      File.write(lockfile, "# mine\n")
      _out, _err, status = run("placecal-theme-transdimension=theme")

      expect(status).to be_success
      expect(File.read(lockfile)).to eq("# mine\n")
    end

    it "writes nothing when core has no Gemfile.lock" do
      _out, _err, status = run("placecal-theme-transdimension=theme")

      expect(status).to be_success
      expect(File).not_to exist(lockfile)
    end

    it "refuses a checkout without the gemspec it needs" do
      File.write(File.join(core, "Gemfile.lock"), core_lock)
      FileUtils.rm(File.join(core, "theme", "placecal-theme-transdimension.gemspec"))
      _out, err, status = run("placecal-theme-transdimension=theme")

      expect(status).not_to be_success
      expect(err).to include("no placecal-theme-transdimension.gemspec")
    end
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
