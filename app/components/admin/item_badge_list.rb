# frozen_string_literal: true

class Components::Admin::ItemBadgeList < Components::Admin::Base
  prop :items, _Interface(:each) # Array or ActiveRecord relation
  prop :icon_name, Symbol
  prop :icon_color, String
  prop :link_path, Symbol
  prop :empty_text, _Nilable(String), default: nil
  prop :vertical, _Boolean, default: false

  def after_initialize
    @empty_text = I18n.t('admin.empty.none_assigned', items: 'items') if @empty_text.nil?
  end

  def view_template
    if @items.any?
      container_class = @vertical ? 'flex flex-col gap-2' : 'flex flex-wrap gap-2'
      div(class: container_class) do
        @items.each do |item|
          link_to view_context.public_send(@link_path, item),
                  class: "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg #{bg_class} #{text_class} text-sm font-medium hover:opacity-80 transition-opacity" do
            icon(@icon_name, size: '3.5')
            plain item_name(item)
          end
        end
      end
    else
      div(class: 'text-center py-6') do
        div(class: 'inline-flex items-center justify-center w-12 h-12 rounded-xl bg-base-200 mb-2') do
          icon(@icon_name, size: '6', css_class: 'text-gray-400')
        end
        p(class: 'text-sm text-gray-600') { @empty_text }
      end
    end
  end

  private

  def item_name(item)
    item.respond_to?(:contextual_name) ? item.contextual_name : item.name
  end

  def bg_class
    @icon_color.split.find { |c| c.start_with?('bg-') }&.gsub(/-100$/, '-50') || 'bg-gray-50'
  end

  def text_class
    @icon_color.split.find { |c| c.start_with?('text-') }&.gsub(/-600$/, '-700') || 'text-gray-700'
  end
end
