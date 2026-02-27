# frozen_string_literal: true

class Views::Admin::Components::RelatedItemsList < Views::Admin::Components::Base
  def initialize(items:, title_attr:, edit_path:, subtitle_attr: nil, empty_message: nil)
    @items = items
    @title_attr = title_attr
    @subtitle_attr = subtitle_attr
    @edit_path = edit_path
    @empty_message = empty_message || 'No items'
  end

  def view_template
    if @items.any?
      div(class: 'grid gap-3 max-w-2xl') do
        @items.each do |item|
          div(class: 'card card-compact bg-base-200/50 border border-base-300') do
            div(class: 'card-body flex-row items-center justify-between') do
              div do
                h3(class: 'font-medium') { item.public_send(@title_attr) }
                subtitle = @subtitle_attr && item.public_send(@subtitle_attr)
                p(class: 'text-xs text-gray-600') { subtitle } if subtitle
              end
              link_to t('admin.actions.edit'), @edit_path.call(item), class: 'btn btn-ghost btn-sm'
            end
          end
        end
      end
    else
      div(class: 'text-center py-8') do
        p(class: 'text-sm text-gray-600') { @empty_message }
      end
    end
  end
end
