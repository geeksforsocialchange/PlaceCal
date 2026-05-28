# frozen_string_literal: true

# Derives a human-friendly application version for display in the UI.
#
# The version is injected at Docker build time via the +APP_VERSION+ env var
# (see Dockerfile / config/deploy.yml), where it is set from
# `git describe --tags --always` (e.g. "v0.27.3" on a tagged release, or
# "v0.27.3-115-gabc1234" when ahead of the latest tag).
#
# Fallback chain for the displayed label:
#   1. ENV['APP_VERSION']        — the git-describe version
#   2. ENV['GIT_REV'][0, 7]      — short commit SHA (legacy)
#   3. the supplied fallback     — 'dev' (admin) or 'main' (public footers)
class AppVersion
  REPO_URL = 'https://github.com/geeksforsocialchange/PlaceCal'

  # @param fallback [String] label to use when no version/commit is available
  # @return [String] the version label to display
  def self.label(fallback: 'dev')
    app_version || git_rev_short || fallback
  end

  # @return [String] a GitHub URL appropriate for the current version:
  #   - the release-tag page when APP_VERSION is set
  #   - the commit diff when only GIT_REV is available
  #   - the repository home otherwise
  def self.url
    if (version = app_version)
      "#{REPO_URL}/releases/tag/#{tag_for(version)}"
    elsif (rev = git_rev)
      "#{REPO_URL}/commit/#{rev}"
    else
      REPO_URL
    end
  end

  def self.app_version
    value = ENV.fetch('APP_VERSION', nil)
    value.presence
  end

  def self.git_rev
    value = ENV.fetch('GIT_REV', nil)
    value.presence
  end

  def self.git_rev_short
    git_rev&.slice(0, 7)
  end

  # Extract the leading tag from a `git describe` string so the release link
  # stays valid even when the build is ahead of the latest tag.
  # "v0.27.3-115-gabc1234" => "v0.27.3"; "v0.27.3" => "v0.27.3"
  def self.tag_for(version)
    version.sub(/-\d+-g[0-9a-f]+\z/, '')
  end

  private_class_method :app_version, :git_rev, :git_rev_short, :tag_for
end
