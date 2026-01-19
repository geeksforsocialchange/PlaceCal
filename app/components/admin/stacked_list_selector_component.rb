# frozen_string_literal: true

module Admin
  class StackedListSelectorComponent < ViewComponent::Base
    include SvgIconsHelper

    # @param field_name [String] Form field name (e.g., "partner[partnership_ids][]")
    # @param items [Array<Object>] Currently selected items (must respond to :id and :name)
    # @param options [Array<Array>] Available options as [name, id] pairs (not needed if read_only)
    # @param permitted_ids [Array<Integer>] IDs the user is allowed to modify (nil = all)
    # @param icon_name [Symbol] Icon to show for each item (default: :partnership)
    # @param icon_color [String] Tailwind color class for icon background
    # @param empty_text [String] Text to show when no items selected
    # @param add_placeholder [String] Placeholder text for the add dropdown
    # @param remove_last_warning [String] Warning when removing last permitted item
    # @param cannot_remove_message [String] Message when trying to remove non-permitted item
    # @param controller [String] Stimulus controller name (default: stacked-list-selector)
    # @param use_tom_select [Boolean] Use tom-select for searchable dropdown (default: false)
    # @param wrapper_class [String] CSS class for test selectors (e.g., "user_partners")
    # @param link_path [Symbol] Path helper method for item links (e.g., :edit_admin_partner_path)
    # @param read_only [Boolean] Display items in read-only mode without add/remove (default: false)
    # rubocop:disable Metrics/ParameterLists
    def initialize(
      field_name:,
      items:,
      options: [],
      permitted_ids: nil,
      icon_name: :partnership,
      icon_color: 'bg-placecal-orange/10 text-placecal-orange',
      empty_text: nil,
      add_placeholder: nil,
      remove_last_warning: nil,
      cannot_remove_message: nil,
      controller: 'stacked-list-selector',
      use_tom_select: false,
      wrapper_class: nil,
      link_path: nil,
      read_only: false
    )
      super()
      @field_name = field_name
      @items = items
      @options = options
      @permitted_ids = permitted_ids
      @icon_name = icon_name
      @icon_color = icon_color
      @empty_text = empty_text || I18n.t('admin.empty.none_assigned', items: 'items')
      @add_placeholder = add_placeholder || I18n.t('admin.placeholders.add_item')
      @remove_last_warning = remove_last_warning
      @cannot_remove_message = cannot_remove_message
      @controller = controller
      @use_tom_select = use_tom_select
      @wrapper_class = wrapper_class
      @link_path = link_path
      @read_only = read_only
    end
    # rubocop:enable Metrics/ParameterLists

    def read_only?
      @read_only
    end

    private

    attr_reader :field_name, :items, :options, :permitted_ids,
                :icon_name, :icon_color, :empty_text, :add_placeholder,
                :remove_last_warning, :cannot_remove_message, :controller, :use_tom_select,
                :wrapper_class, :link_path

    def item_link(item)
      return nil unless link_path

      helpers.public_send(link_path, item)
    end

    def selected_ids
      items.map(&:id)
    end

    def permitted_json
      permitted_ids&.to_json || '[]'
    end

    def option_disabled?(id)
      selected_ids.include?(id)
    end

    def item_removable?(item)
      return true if permitted_ids.nil?

      permitted_ids.include?(item.id)
    end

    def item_display_name(item)
      if item.respond_to?(:display_name)
        item.display_name
      else
        item.name
      end
    end
  end
end
