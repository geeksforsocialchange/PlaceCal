# frozen_string_literal: true

# @display context directory
class UI::SearchBarPreview < Lookbook::Preview
  # White bar with a shadow and a primary button, for the directory hero.
  # @label Light
  def light
    render(Components::UI::SearchBar.new(action: "#", tone: :light, placeholder: "Search for events, groups or places", button_label: "Search"))
  end

  # Panel-coloured bar with a smaller dark button, for search inside a page.
  # @label Panel, small
  def panel
    render(Components::UI::SearchBar.new(action: "#", size: :sm, placeholder: "Search partnerships", button_label: "Search"))
  end
end
