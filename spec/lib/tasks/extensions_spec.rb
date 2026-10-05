# frozen_string_literal: true

require "rails_helper"
require "rake"
require "tmpdir"

# Bumping an extension to a released tag (#3368 WP 5.2). doc/extensions.md
# calls the Gemfile edit plus the relock the whole deploy step for an extension
# change, so the two have to land together or not at all.
RSpec.describe "placecal:extension:bump", type: :task do
  let(:core) { Pathname(Dir.mktmpdir) }
  let(:gemfile) { core.join("Gemfile") }

  let(:source) do
    <<~RUBY
      group :extensions do
        gem 'placecal-theme-mossley', github: 'geeksforsocialchange/placecal-theme-mossley', tag: 'v0.1.1'
      end
    RUBY
  end

  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    gemfile.write(source)
    # The task edits Rails.root's own Gemfile. Point it at a throwaway one so
    # the spec cannot rewrite the checkout it is running in.
    allow(Rails).to receive(:root).and_return(core)
  end

  after { FileUtils.remove_entry(core) }

  def run_task(name, version)
    task = Rake::Task["placecal:extension:bump"]
    task.reenable
    task.invoke(name, version)
  end

  it "pins the tag and relocks" do
    allow(Bundler).to receive(:with_unbundled_env).and_return(true)

    expect { run_task("placecal-theme-mossley", "0.1.2") }.to output(/Pinned/).to_stdout

    expect(gemfile.read).to include("tag: 'v0.1.2'")
  end

  # A bumped Gemfile beside a stale Gemfile.lock is exactly the pair the task's
  # own closing line says must be committed together, so a failed relock must
  # not leave one behind.
  it "puts the Gemfile back when bundle lock fails" do
    allow(Bundler).to receive(:with_unbundled_env).and_return(false)

    expect { run_task("placecal-theme-mossley", "0.1.2") }
      .to raise_error(SystemExit)
      .and output(/Pinned/).to_stdout

    expect(gemfile.read).to eq(source)
  end

  it "leaves the Gemfile alone when the version is not a release number" do
    expect { run_task("placecal-theme-mossley", "0.1") }.to raise_error(SystemExit)

    expect(gemfile.read).to eq(source)
  end
end
