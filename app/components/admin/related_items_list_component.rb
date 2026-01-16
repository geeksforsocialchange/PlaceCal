# frozen_string_literal: true

module Admin
  # Displays a list of related items (like calendars, users) with edit links.
  # Used in form tabs to show associated records.
  #
  # @example Basic usage
  #   <%= render Admin::RelatedItemsListComponent.new(
  #     items: @partner.calendars,
  #     title_attr: :name,
  #     subtitle_attr: :source,
  #     edit_path: ->(item) { edit_admin_calendar_path(item) }
  #   ) %>
  #
  class RelatedItemsListComponent < ViewComponent::Base
    include SvgIconsHelper

    # @param items [ActiveRecord::Relation, Array] Collection of items to display
    # @param title_attr [Symbol] Attribute to use for item title
    # @param subtitle_attr [Symbol, nil] Optional attribute for subtitle
    # @param edit_path [Proc] Lambda that returns the edit path for an item
    # @param empty_message [String] Message when no items
    def initialize(items:, title_attr:, edit_path:, subtitle_attr: nil, empty_message: nil)
      super()
      @items = items
      @title_attr = title_attr
      @subtitle_attr = subtitle_attr
      @edit_path = edit_path
      @empty_message = empty_message || 'No items'
    end

    private

    attr_reader :items, :title_attr, :subtitle_attr, :edit_path, :empty_message

    def item_title(item)
      item.public_send(title_attr)
    end

    def item_subtitle(item)
      return nil unless subtitle_attr

      item.public_send(subtitle_attr)
    end

    def item_edit_path(item)
      edit_path.call(item)
    end
  end
end
