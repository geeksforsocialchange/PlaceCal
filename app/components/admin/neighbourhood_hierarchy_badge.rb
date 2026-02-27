# frozen_string_literal: true

class Components::Admin::NeighbourhoodHierarchyBadge < Components::Admin::Base
  include NeighbourhoodsHelper

  prop :neighbourhood, ::Neighbourhood
  prop :max_levels, _Nilable(Integer), default: nil
  prop :show_icons, _Boolean, default: false
  prop :truncate, _Boolean, default: true
  prop :link_each, _Boolean, default: false
  prop :compact, _Boolean, default: false

  def after_initialize
    @truncated = false
  end

  def view_template
    div(class: 'inline-flex flex-wrap items-center gap-1') do
      if truncated?
        span(class: 'text-gray-400 text-sm') { '...' }
        span(class: 'text-gray-300') { '/' }
      end

      hierarchy_items.each_with_index do |item, index|
        span(class: 'text-gray-300') { '/' } if index.positive?

        if @link_each
          link_to admin_neighbourhood_path(item),
                  class: "inline-flex items-center gap-1.5 #{badge_size_classes} rounded #{level_colour(item.level)} hover:opacity-80 transition-opacity" do
            span(class: 'inline-flex items-center justify-center w-4 h-4 rounded-full bg-current/10 text-[9px] font-bold') { "L#{item.level}" } if @show_icons
            plain item.shortname
          end
        else
          span(class: "inline-flex items-center gap-1.5 #{badge_size_classes} rounded #{level_colour(item.level)}") do
            span(class: 'inline-flex items-center justify-center w-4 h-4 rounded-full bg-current/10 text-[9px] font-bold') { "L#{item.level}" } if @show_icons
            plain item.shortname
          end
        end
      end
    end
  end

  private

  def hierarchy_items
    return [] unless @neighbourhood

    items = @neighbourhood.hierarchy_path

    if @max_levels && items.length > @max_levels && @truncate
      items = items.last(@max_levels)
      @truncated = true
    end

    items
  end

  def truncated?
    @truncated
  end

  def level_colour(level)
    NeighbourhoodsHelper::LEVEL_COLOURS[level.is_a?(Integer) ? level : Neighbourhood::LEVELS[level&.to_sym]] ||
      NeighbourhoodsHelper::DEFAULT_COLOUR
  end

  def badge_size_classes
    @compact ? 'px-1.5 py-0.5 text-xs' : 'px-2 py-0.5 text-sm'
  end
end
