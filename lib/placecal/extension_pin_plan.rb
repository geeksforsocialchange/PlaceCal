# frozen_string_literal: true

module PlaceCal
  # What bin/extension-pin-bumps does for one extension, decided from what the
  # script fetched from GitHub so it can be specced without calling it.
  module ExtensionPinPlan
    # action is :open or :skip; close lists the open pin PRs this one supersedes.
    Plan = Struct.new(:action, :branch, :reason, :close, :superseded_by, keyword_init: true)

    module_function

    # @param name [String] gem name, as it appears in the Gemfile
    # @return [String] the branch a pin PR for that version is opened from
    def branch(name, version)
      "extensions/#{name}-v#{version}"
    end

    # @param name [String] gem name
    # @param current [String] the version the Gemfile pins, like "1.2.3"
    # @param latest [String, nil] the newest release tag's version
    # @param target_prs [Array<Hash>] every PR from latest's pin branch, as
    #   { number:, state: } with state OPEN, CLOSED or MERGED
    # @param open_prs [Array<Hash>] open PRs in the repo, as { number:, head: }
    # @return [Plan]
    def call(name:, current:, latest:, target_prs:, open_prs:)
      pin_prs = open_pin_prs(name, open_prs)

      unless latest && Gem::Version.new(latest) > Gem::Version.new(current)
        stale = pin_prs.select { |pr| Gem::Version.new(pr[:version]) <= Gem::Version.new(current) }
        return Plan.new(action: :skip, reason: "v#{current} is the latest", close: stale, superseded_by: current)
      end

      target = branch(name, latest)
      others = pin_prs.reject { |pr| pr[:version] == latest }
      by_state = target_prs.to_h { |pr| [pr[:state], pr[:number]] }

      if by_state['OPEN']
        skip(target, "PR ##{by_state['OPEN']} for v#{latest} is already open", others, latest)
      elsif by_state['MERGED']
        skip(target, "PR ##{by_state['MERGED']} for v#{latest} was merged", [], latest)
      elsif by_state['CLOSED']
        skip(target, "PR ##{by_state['CLOSED']} for v#{latest} was closed without merging", [], latest)
      else
        Plan.new(action: :open, branch: target, close: others, superseded_by: latest)
      end
    end

    def skip(branch, reason, close, superseded_by)
      Plan.new(action: :skip, branch: branch, reason: reason, close: close, superseded_by: superseded_by)
    end

    # @return [Array<Hash>] { number:, version: } for each open pin PR of +name+
    def open_pin_prs(name, open_prs)
      pattern = %r{\Aextensions/#{Regexp.escape(name)}-v(\d+\.\d+\.\d+)\z}
      open_prs.filter_map do |pr|
        version = pr[:head].to_s[pattern, 1]
        { number: pr[:number], version: version } if version
      end
    end
  end
end
