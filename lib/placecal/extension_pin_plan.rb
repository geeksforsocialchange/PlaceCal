# frozen_string_literal: true

module PlaceCal
  # bin/extension-pin-bumps' decision for one extension, separated so it specs without GitHub.
  module ExtensionPinPlan
    # action is :open or :skip; close lists the open pin PRs this one supersedes.
    Plan = Struct.new(:action, :branch, :reason, :close, :superseded_by, keyword_init: true)

    module_function

    def branch(name, version)
      "extensions/#{name}-v#{version}"
    end

    # PR states are GitHub's OPEN, CLOSED or MERGED; a closed version is never reopened.
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

    def open_pin_prs(name, open_prs)
      pattern = %r{\Aextensions/#{Regexp.escape(name)}-v(\d+\.\d+\.\d+)\z}
      open_prs.filter_map do |pr|
        version = pr[:head].to_s[pattern, 1]
        { number: pr[:number], version: version } if version
      end
    end
  end
end
