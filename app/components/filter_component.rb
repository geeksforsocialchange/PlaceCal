# frozen_string_literal: true

# Generic filter dropdown component for radio button selections
#
# @example Neighbourhood filter
#   <%= render FilterComponent.new(
#     name: "neighbourhood",
#     label: "Filter by ward",
#     items: neighbourhoods.map { |n| { id: n[:neighbourhood].id, name: n[:neighbourhood].name, count: n[:count] } },
#     selected_id: @selected_neighbourhood,
#     controller: "event-filter",
#     toggle_action: "toggleNeighbourhood",
#     submit_action: "submitNeighbourhood",
#     reset_action: "resetNeighbourhood"
#   ) %>
#
class FilterComponent < ViewComponent::Base
  include SvgIconsHelper

  # rubocop:disable Metrics/ParameterLists
  def initialize(name:, label:, items:, controller:, toggle_action:, submit_action:, reset_action:, selected_id: nil)
    super()
    @name = name
    @label = label
    @items = items
    @selected_id = selected_id.to_i
    @controller = controller
    @toggle_action = toggle_action
    @submit_action = submit_action
    @reset_action = reset_action
  end
  # rubocop:enable Metrics/ParameterLists

  attr_reader :name, :label, :items, :controller

  def selected?(id)
    @selected_id == id
  end

  def filter_active?
    @selected_id.positive?
  end

  def selected_item_name
    selected_item = items.find { |item| item[:id] == @selected_id }
    selected_item&.dig(:name)
  end

  def button_text
    filter_active? ? selected_item_name : label
  end

  def toggle_action_value
    "click->#{controller}##{@toggle_action}"
  end

  def submit_action_value
    "change->#{controller}##{@submit_action}"
  end

  def reset_action_value
    "click->#{controller}##{@reset_action}"
  end

  def render?
    items.any?
  end
end
