# frozen_string_literal: true

class Components::Admin::StackedListSelector < Components::Admin::Base
  prop :field_name, String
  prop :items, _Any
  prop :options, _Any, default: -> { [] }
  prop :permitted_ids, _Nilable(_Any), default: nil
  prop :icon_name, Symbol, default: :partnership
  prop :icon_color, String, default: 'bg-placecal-orange/10 text-placecal-orange'
  prop :empty_text, _Nilable(String), default: nil
  prop :add_placeholder, _Nilable(String), default: nil
  prop :remove_last_warning, _Nilable(String), default: nil
  prop :cannot_remove_message, _Nilable(String), default: nil
  prop :controller, String, default: 'stacked-list-selector'
  prop :use_tom_select, _Boolean, default: false
  prop :wrapper_class, _Nilable(String), default: nil
  prop :link_path, _Nilable(_Any), default: nil
  prop :read_only, _Boolean, default: false

  def after_initialize
    @empty_text = I18n.t('admin.empty.none_assigned', items: 'items') if @empty_text.nil?
    @add_placeholder = I18n.t('admin.placeholders.add_item') if @add_placeholder.nil?
  end

  def view_template
    if @read_only
      render_read_only
    else
      render_interactive
    end
  end

  private

  def render_read_only
    div(class: @wrapper_class) do
      if @items.any?
        div(class: 'space-y-2') do
          @items.each { |item| render_read_only_item(item) }
        end
      else
        render_empty_state(size: '14')
      end
    end
  end

  def render_read_only_item(item)
    div(class: 'flex items-center gap-3 p-3 bg-base-200/50 rounded-xl border border-base-300/50') do
      render_item_icon
      render_item_name(item)
      span(class: 'badge badge-ghost badge-sm') { t('admin.labels.locked') }
    end
  end

  def render_interactive
    wrapper_data = {
      controller: @controller,
      "#{@controller}-permitted-value" => permitted_json,
      "#{@controller}-field-name-value" => @field_name,
      "#{@controller}-icon-value" => @icon_name,
      "#{@controller}-icon-color-value" => @icon_color
    }
    wrapper_data["#{@controller}-remove-last-warning-value"] = @remove_last_warning if @remove_last_warning.present?
    wrapper_data["#{@controller}-cannot-remove-message-value"] = @cannot_remove_message if @cannot_remove_message.present?

    div(class: @wrapper_class, data: wrapper_data) do
      input(type: 'hidden', name: @field_name, value: '')
      render_selected_items
      render_empty_state(size: '14')
      render_add_dropdown
      render_template
    end
  end

  def render_selected_items
    div(class: 'space-y-2 mb-4', **{ "data-#{@controller}-target" => 'list' }) do
      @items.each { |item| render_selected_item(item) }
    end
  end

  def render_selected_item(item)
    div(
      class: 'group flex items-center gap-3 p-3 bg-base-200/80 rounded-xl border border-base-300/50 hover:border-base-300 transition-all',
      data_item_id: item.id,
      data_item_name: item_display_name(item)
    ) do
      input(type: 'hidden', name: @field_name, value: item.id)
      render_item_icon
      render_item_name(item)
      if item_removable?(item)
        button(
          type: 'button',
          class: 'btn btn-ghost btn-sm btn-square opacity-0 group-hover:opacity-100 text-gray-500 hover:text-error hover:bg-error/10 transition-all',
          data_action: "click->#{@controller}#remove",
          aria_label: t('admin.actions.remove')
        ) { icon(:x, size: '4') }
      else
        span(class: 'badge badge-ghost badge-sm') { t('admin.labels.locked') }
      end
    end
  end

  def render_item_icon
    div(class: "shrink-0 w-9 h-9 rounded-lg #{@icon_color} flex items-center justify-center") do
      icon(@icon_name, size: '5')
    end
  end

  def render_item_name(item)
    link = item_link(item)
    if link
      link_to item_display_name(item), link,
              class: 'flex-1 font-medium text-sm text-base-content/90 hover:text-orange-600 hover:underline'
    else
      span(class: 'flex-1 font-medium text-sm text-base-content/90') { item_display_name(item) }
    end
  end

  def render_empty_state(size:)
    hidden = @items.any? ? 'hidden' : ''
    div(
      class: "text-center py-8 #{hidden}",
      **(@read_only ? {} : { "data-#{@controller}-target" => 'empty' })
    ) do
      div(class: "inline-flex items-center justify-center w-#{size} h-#{size} rounded-2xl bg-base-200 mb-3") do
        icon(@icon_name, size: '7', css_class: 'text-gray-400')
      end
      p(class: 'text-sm text-gray-600') { @empty_text }
    end
  end

  def render_add_dropdown
    div(class: 'relative') do
      select(
        class: 'w-full',
        aria_label: @add_placeholder,
        **{ "data-#{@controller}-target" => 'select' },
        data_action: "change->#{@controller}#add",
        data_controller: 'tom-select'
      ) do
        option(value: '') { @add_placeholder }
        @options.each do |name, id|
          option(value: id, **(selected_ids.include?(id) ? { disabled: true } : {})) { name }
        end
      end
    end
  end

  def render_template
    template(**{ "data-#{@controller}-target" => 'template' }) do
      div(
        class: 'group flex items-center gap-3 p-3 bg-base-200/80 rounded-xl border border-base-300/50 hover:border-base-300 transition-all',
        data_item_id: 'ITEM_ID',
        data_item_name: 'ITEM_NAME'
      ) do
        input(type: 'hidden', name: @field_name, value: 'ITEM_ID')
        render_item_icon
        span(class: 'flex-1 font-medium text-sm text-base-content/90') { 'ITEM_NAME' }
        button(
          type: 'button',
          class: 'btn btn-ghost btn-sm btn-square opacity-0 group-hover:opacity-100 text-gray-500 hover:text-error hover:bg-error/10 transition-all',
          data_action: "click->#{@controller}#remove",
          aria_label: t('admin.actions.remove')
        ) { icon(:x, size: '4') }
      end
    end
  end

  def item_link(item)
    return nil unless @link_path

    view_context.public_send(@link_path, item)
  end

  def selected_ids
    @items.map(&:id)
  end

  def permitted_json
    @permitted_ids&.to_json || '[]'
  end

  def item_removable?(item)
    return true if @permitted_ids.nil?

    @permitted_ids.include?(item.id)
  end

  def item_display_name(item)
    item.respond_to?(:display_name) ? item.display_name : item.name
  end
end
