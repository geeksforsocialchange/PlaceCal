# frozen_string_literal: true

require "spec_helper"
require "open3"
require "tmpdir"
require "fileutils"

# The CI guard behind the extension contract (see the Trust section of
# doc/extensions.md). It is exercised against synthetic gem trees so the
# expectations do not move when the real theme gem does.
RSpec.describe "bin/check-extension-tree" do
  APP_ROOT = File.expand_path("../..", __dir__)
  SCRIPT = File.join(APP_ROOT, "bin", "check-extension-tree")

  def run(*roots)
    Open3.capture3("bundle", "exec", SCRIPT, *roots, chdir: APP_ROOT)
  end

  # The reusable extension workflow runs the guard before it bundles anything,
  # so an extension that ships a model fails in seconds rather than after an
  # install and a core asset build.
  def run_unbundled(*roots)
    Open3.capture3({ "RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil }, "ruby", SCRIPT, *roots, chdir: APP_ROOT)
  end

  def git_init(root)
    Open3.capture3("git", "init", "-q", root)
    Open3.capture3("git", "-C", root, "add", "-A")
  end

  def build_tree(root, paths)
    paths.each do |path|
      full = File.join(root, path)
      FileUtils.mkdir_p(File.dirname(full))
      FileUtils.touch(full)
    end
  end

  let(:contract_abiding) do
    [
      "app/views/foo/home.rb",
      "app/components/foo/footer.rb",
      "app/assets/builds/foo/theme.css",
      "app/tailwind/theme.css",
      "config/locales/en.yml",
      "content/about.md",
      "doc/notes.md",
      "bin/foo-dev",
      "spec/spec_helper.rb",
      "goldens/README.md",
      ".github/workflows/test.yml",
      "lib/foo.rb",
      "lib/foo/engine.rb",
      "lib/foo/version.rb",
      "lib/tasks/foo.rake",
      "README.md",
      "LICENSE",
      "Rakefile",
      "Gemfile",
      "package.json",
      "yarn.lock",
      "foo.gemspec",
      ".rubocop.yml",
      ".node-version"
    ]
  end

  it "passes a tree that stays inside the contract" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "foo")
      build_tree(root, contract_abiding)

      stdout, _stderr, status = run(root)

      expect(status).to be_success
      expect(stdout).to include("every extension stays inside the contract")
    end
  end

  # CI checks the gem out under a directory called `theme`, so the name has to
  # come from the gemspec or the gem's own entry file counts as stray lib code.
  it "names an explicit root after its gemspec, not its directory" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "theme")
      # The real shape: gem placecal-theme-foo, module foo, so the entry file
      # is only allowed once the guard knows the gem's name.
      build_tree(root, contract_abiding - ["foo.gemspec", "lib/foo.rb"] +
                       ["placecal-theme-foo.gemspec", "lib/placecal-theme-foo.rb"])

      stdout, stderr, status = run(root)

      expect(status).to be_success, stderr
      expect(stdout).to include("placecal-theme-foo: #{contract_abiding.length} files checked")
    end
  end

  it "fails on models, controllers, migrations, routes, initializers and stray lib code" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "foo")
      build_tree(root, contract_abiding + [
        "app/models/thing.rb",
        "app/controllers/things_controller.rb",
        "db/migrate/001_add_things.rb",
        "config/routes.rb",
        "config/initializers/boot.rb",
        "lib/foo/sneaky.rb",
        "lib/elsewhere/payload.rb"
      ])

      _stdout, stderr, status = run(root)

      expect(status).not_to be_success
      expect(stderr).to include("app/models/thing.rb")
      expect(stderr).to include("app/controllers/things_controller.rb")
      expect(stderr).to include("db/migrate/001_add_things.rb")
      expect(stderr).to include("config/routes.rb")
      expect(stderr).to include("config/initializers/boot.rb")
      expect(stderr).to include("lib/foo/sneaky.rb")
      expect(stderr).to include("lib/elsewhere/payload.rb")
    end
  end

  it "runs against an explicit root with no bundle at all" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "foo")
      build_tree(root, contract_abiding)

      stdout, stderr, status = run_unbundled(root)

      expect(status).to be_success, stderr
      expect(stdout).to include("every extension stays inside the contract")
    end
  end

  # A developer's theme checkout has node_modules/ and tmp/ in it and a
  # released gem does not, so a filesystem walk buried the real answer in
  # hundreds of false offenders. In a git work tree the files the gem ships
  # are exactly the tracked ones.
  it "lists tracked files only when the root is a git work tree" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "foo")
      build_tree(root, contract_abiding)
      git_init(root)
      build_tree(root, ["node_modules/left-pad/index.js", "tmp/theme-check.css", "app/models/untracked.rb"])

      stdout, stderr, status = run(root)

      expect(status).to be_success, stderr
      expect(stdout).to include("every extension stays inside the contract")
    end
  end

  it "skips build output and dependencies when there is no git metadata to go on" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "foo")
      build_tree(root, contract_abiding + [
        "node_modules/left-pad/index.js",
        "tmp/theme-check.css",
        "coverage/index.html",
        "vendor/bundle/thing.rb"
      ])

      stdout, stderr, status = run(root)

      expect(status).to be_success, stderr
      expect(stdout).to include("every extension stays inside the contract")
    end
  end

  it "names the whole allowlist when it fails, not a shorter version of it" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "foo")
      build_tree(root, contract_abiding + ["app/models/thing.rb"])

      _stdout, stderr, _status = run(root)

      expect(stderr).to include("bin", "spec", "goldens", ".github", "app/tailwind", "app/scss")
      expect(stderr).to include("lib/tasks/*.rake")
      expect(stderr).to include("may not ship models, controllers, routes, migrations or initializers")
    end
  end

  # Both theme repos ship one beside their LICENCE, recording the carve-out for
  # the assets the gem does not license under its own terms.
  it "allows a NOTICE beside the LICENCE" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "foo")
      build_tree(root, contract_abiding + ["NOTICE"])

      _stdout, _stderr, status = run(root)

      expect(status).to be_success
    end
  end

  it "ignores the gem's own git metadata" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "foo")
      build_tree(root, contract_abiding + [".git/config", ".git/objects/ab/cdef"])

      _stdout, _stderr, status = run(root)

      expect(status).to be_success
    end
  end
end
