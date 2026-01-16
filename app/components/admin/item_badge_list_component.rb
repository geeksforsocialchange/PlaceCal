# frozen_string_literal: true

module Admin
  class ItemBadgeListComponent < ViewComponent::Base
    include SvgIconsHelper

    # @param items [Array<Object>] Items to display (must respond to :id and :name or :contextual_name)
    # @param icon_name [Symbol] Icon to show for each item (:partner, :partnership, :map_pin, etc.)
    # @param icon_color [String] Tailwind classes for icon/badge colors (e.g., "bg-emerald-100 text-emerald-600")
    # @param link_path [Symbol] Route helper name for generating links (:edit_admin_partner_path, etc.)
    # @param empty_text [String] Text to show when no items (optional)
    # @param vertical [Boolean] Stack items vertically instead of wrapping horizontally (default: false)
    # rubocop:disable Metrics/ParameterLists
    def initialize(items:, icon_name:, icon_color:, link_path:, empty_text: nil, vertical: false)
      super()
      @items = items
      @icon_name = icon_name
      @icon_color = icon_color
      @link_path = link_path
      @empty_text = empty_text || I18n.t('admin.empty.none_assigned', items: 'items')
      @vertical = vertical
    end
    # rubocop:enable Metrics/ParameterLists

    private

    attr_reader :items, :icon_name, :icon_color, :link_path, :empty_text, :vertical

    def container_class
      vertical ? 'flex flex-col gap-2' : 'flex flex-wrap gap-2'
    end

    def item_path(item)
      helpers.send(link_path, item)
    end

    def item_name(item)
      item.respond_to?(:contextual_name) ? item.contextual_name : item.name
    end

    # Extract background class from icon_color (e.g., "bg-emerald-100" -> "bg-emerald-50")
    def bg_class
      # Use the bg- class directly, converting -100 to -50 for lighter background
      icon_color.split.find { |c| c.start_with?('bg-') }&.gsub(/-100$/, '-50') || 'bg-gray-50'
    end

    # Extract text class from icon_color (e.g., "text-emerald-600" -> "text-emerald-700")
    def text_class
      icon_color.split.find { |c| c.start_with?('text-') }&.gsub(/-600$/, '-700') || 'text-gray-700'
    end
  end
end
