# frozen_string_literal: true

class Components::Filter < Components::Base
  prop :name, String
  prop :label, String
  prop :items, _Any
  prop :controller, String
  prop :toggle_action, String
  prop :submit_action, String
  prop :reset_action, String
  prop :selected_id, _Nilable(_Any), default: nil

  def after_initialize
    @selected_id = @selected_id.to_i
  end

  def view_template
    return unless @items.any?

    render_toggle
    render_dropdown
  end

  private

  def render_toggle
    div(class: 'filters__toggle') do
      button(type: 'button', data: { action: toggle_action_value }) do
        span(class: 'icon icon--arrow-down') { plain "\u2193" }
        span(class: 'filters__link', data: { "#{@controller}-target": "#{@name}Text" }) do
          button_text
        end
      end
    end
  end

  def render_dropdown # rubocop:disable Metrics/MethodLength
    div(class: 'filters__dropdown filters__dropdown--hidden', data: { "#{@controller}-target": "#{@name}Dropdown" }) do
      div(class: 'filters__group') do
        @items.each do |item|
          div(class: 'filters__option') do
            radio_button_tag(
              @name,
              item[:id],
              selected?(item[:id]),
              data: { action: submit_action_value },
              class: 'tag__button'
            )
            label_tag(
              "#{@name}_#{item[:id]}",
              "#{item[:name]} (#{item[:count]})",
              class: 'filters__label'
            )
          end
        end
      end
      button(type: 'button', data: { action: reset_action_value }, class: 'btn size-patch filter__reset') { 'Reset' } if filter_active?
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

  def button_text
    filter_active? ? selected_item_name : @label
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
