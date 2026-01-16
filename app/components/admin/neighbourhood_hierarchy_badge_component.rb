# frozen_string_literal: true

module Admin
  # Displays a neighbourhood's full hierarchy as colored badges
  # Example output: "England / South East / East Sussex / Wealden / Uckfield North"
  class NeighbourhoodHierarchyBadgeComponent < ViewComponent::Base
    include SvgIconsHelper
    include NeighbourhoodsHelper

    # @param neighbourhood [Neighbourhood] The neighbourhood to display
    # @param options [Hash] Display options
    # @option options [Integer, nil] :max_levels Maximum levels to show (nil = all)
    # @option options [Boolean] :show_icons Show level-appropriate icons
    # @option options [Boolean] :truncate Truncate with "..." if exceeding max_levels
    # @option options [Boolean] :link_each Make each level a clickable link
    # @option options [Boolean] :compact Use smaller badges
    def initialize(neighbourhood:, **options) # rubocop:disable Metrics/ParameterLists
      super()
      @neighbourhood = neighbourhood
      @max_levels = options[:max_levels]
      @show_icons = options.fetch(:show_icons, false)
      @truncate = options.fetch(:truncate, true)
      @link_each = options.fetch(:link_each, false)
      @compact = options.fetch(:compact, false)
      @truncated = false
    end

    private

    attr_reader :neighbourhood, :max_levels, :show_icons, :truncate, :link_each, :compact

    def hierarchy_items
      return [] unless neighbourhood

      items = neighbourhood.hierarchy_path

      if max_levels && items.length > max_levels && truncate
        # Keep the most specific levels (current + parents up to max)
        items = items.last(max_levels)
        @truncated = true
      end

      items
    end

    def truncated?
      @truncated
    end

    # Colour classes for each level
    def level_colour(level)
      NeighbourhoodsHelper::LEVEL_COLOURS[level.is_a?(Integer) ? level : Neighbourhood::LEVELS[level&.to_sym]] ||
        NeighbourhoodsHelper::DEFAULT_COLOUR
    end

    # Icon for each level
    def level_icon(level)
      case level
      when 5 then :globe
      when 4 then :map
      when 1 then :neighbourhood
      else :map_pin # county (3), district (2), and unknown
      end
    end

    def badge_size_classes
      compact ? 'px-1.5 py-0.5 text-xs' : 'px-2 py-0.5 text-sm'
    end

    def icon_size
      compact ? '3' : '4'
    end
  end
end
