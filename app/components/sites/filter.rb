# frozen_string_literal: true

class Components::Sites::Filter < Components::Base
  prop :name, String
  prop :label, String
  prop :items, Array
  prop :controller, String
  prop :toggle_action, String
  prop :submit_action, String
  prop :reset_action, String
  prop :selected_id, Integer, default: 0
  # Extra class on the options group, so a caller with more than one Filter on
  # a page (the neighbourhood filter, say) can give its dropdown a hook of
  # its own, alongside the shared filters__group class.
  prop :group_class, _Nilable(String), default: nil

  TOGGLE = 'filters__toggle flex items-center'
  TOGGLE_BUTTON = 'border-0 bg-transparent font-sans cursor-pointer flex items-center gap-1'
  TOGGLE_ICON = 'size-2 text-primary'
  DROPDOWN = 'filters__dropdown filters__dropdown--hidden dropdown-hidden:hidden bg-background shadow-dropdown p-3 absolute top-8 left-0 ' \
             'z-500 text-left whitespace-nowrap max-w-screen-inset overflow-x-auto'
  OPTION = 'filters__option py-1 grid grid-cols-auto-main gap-2 items-center'

  def view_template
    return unless @items.any?

    render_toggle
    render_dropdown
  end

  private

  def render_toggle
    div(class: TOGGLE) do
      button(type: 'button', class: TOGGLE_BUTTON, data: { action: toggle_action_value }) do
        raw(view_context.icon(:triangle_down, size: nil, css_class: TOGGLE_ICON))
        span(class: 'filters__toggle-label mr-1') { @label }
        span(class: 'filters__toggle-value border-b-2 border-rules-dark', data: { "#{@controller}-target": "#{@name}Text" }) do
          toggle_value
        end
      end
    end
  end

  def render_dropdown
    div(class: DROPDOWN, data: { "#{@controller}-target": "#{@name}Dropdown" }) do
      render_filter_options
      render_reset_button
    end
  end

  def render_filter_options
    div(class: ['filters__group', @group_class].compact.join(' ')) do
      @items.each { |item| render_filter_option(item) }
    end
  end

  def render_filter_option(item)
    div(class: OPTION) do
      radio_button_tag(
        @name,
        item[:id],
        selected?(item[:id]),
        data: {
          action: submit_action_value,
          "#{@controller}-target": @name
        },
        class: 'peer'
      )
      label_tag(
        "#{@name}_#{item[:id]}",
        "#{item[:name]} (#{item[:count]})",
        class: 'filters__label text-left ml-1 peer-checked:font-bold'
      )
    end
  end

  def render_reset_button
    return unless filter_active?

    UI::Button(variant: :outline, size: :sm, data: { action: reset_action_value }, class: 'mt-3') do
      t('filters.reset_button')
    end
  end

  def selected?(id)
    @selected_id == id
  end

  def filter_active?
    @selected_id.positive?
  end

  def selected_item_name
    selected_item = @items.find { |item| item[:id] == @selected_id }
    selected_item&.dig(:name)
  end

  def toggle_value
    filter_active? ? selected_item_name : t('filters.show_all')
  end

  def toggle_action_value
    "click->#{@controller}##{@toggle_action}"
  end

  def submit_action_value
    "change->#{@controller}##{@submit_action}"
  end

  def reset_action_value
    "click->#{@controller}##{@reset_action}"
  end
end
