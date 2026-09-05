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

  it "ignores the gem's own git metadata" do
    Dir.mktmpdir do |dir|
      root = File.join(dir, "foo")
      build_tree(root, contract_abiding + [".git/config", ".git/objects/ab/cdef"])

      _stdout, _stderr, status = run(root)

      expect(status).to be_success
    end
  end
end
