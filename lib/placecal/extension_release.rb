# frozen_string_literal: true

module PlaceCal
  # Rewriting an extension's pinned tag in core's Gemfile (#3368 WP 5.2).
  #
  # doc/extensions.md says bumping the tag and running `bundle lock` is the
  # whole deploy step for an extension change, so it is worth having exactly
  # one way to do it. lib/tasks/extensions.rake is that way; this is the edit,
  # split out so it can be tested without touching core's own Gemfile.
  module ExtensionRelease
    VERSION_FORMAT = /\A\d+\.\d+\.\d+\z/

    module_function

    # @param source [String] core's Gemfile
    # @param name [String] gem name, as it appears in the Gemfile
    # @param version [String] "0.1.2" or "v0.1.2"
    # @return [String] the Gemfile with that gem's tag rewritten
    # @raise [ArgumentError] on a version that is not semver, a gem the
    #   Gemfile does not have, or a gem that is not pinned by tag
    def bump(source, name, version)
      version = normalize_version(version)
      lines = source.lines
      range = entry_range(lines, name)
      raise ArgumentError, "#{name} is not in the Gemfile" if range.nil?

      entry = lines[range].join
      raise ArgumentError, "#{name} is not pinned by tag in the Gemfile" unless entry.match?(/tag:\s*['"]/)

      lines[range] = entry.sub(/tag:\s*['"][^'"]*['"]/, "tag: '#{version}'")
      lines.join
    end

    # @param version [String]
    # @return [String] the tag, with its leading v
    def normalize_version(version)
      number = version.to_s.strip.delete_prefix('v')
      raise ArgumentError, "#{version.inspect} is not a version like 1.2.3" unless number.match?(VERSION_FORMAT)

      "v#{number}"
    end

    # A Gemfile entry may wrap over several lines, with the tag on one of its
    # own. A line ending in a comma continues onto the next.
    #
    # @return [Range, nil]
    def entry_range(lines, name)
      first = lines.index { |line| line.match?(/^\s*gem\s+['"]#{Regexp.escape(name)}['"]/) }
      return nil if first.nil?

      last = first
      last += 1 while lines[last].rstrip.end_with?(',') && lines[last + 1]
      (first..last)
    end
  end
end
