# frozen_string_literal: true

# Step definitions for enhanced select box interactions (Select2/Tom Select)
# These select boxes create overlay elements that require special handling

# Select a single option from a searchable drop down select box
When("I select {string} from the {string} drop down select box") do |option, field|
  select2_select(option, from: field)
end

# Select from the service area drop down (nested Cocoon field)
When("I select {string} from the service area drop down select box") do |option|
  # Find the most recently added service area field
  within(".sites_neighbourhoods") do
    container = find(".select2-container", match: :first)
    container.click
  end

  # Wait for dropdown and select option
  within(".select2-dropdown") do
    find(".select2-results__option", text: option, match: :prefer_exact).click
  end
end

# Select multiple options from a searchable drop down select box
When("I select {string} and {string} from the {string} drop down select box") do |option1, option2, field|
  select2_select(option1, from: field)
  select2_select(option2, from: field)
end

# Clear all selections from a searchable drop down
When("I clear the {string} drop down select box") do |field|
  select2_clear(field)
end

# Verify a drop down select box has a specific option selected
Then("the {string} drop down select box should have {string} selected") do |field, option|
  expect(page).to have_select2_selection(field, option)
end

# Verify a drop down select box does not have a specific option selected
Then("the {string} drop down select box should not have {string} selected") do |field, option|
  expect(page).not_to have_select2_selection(field, option)
end

# Helper methods for Select2/Tom Select interactions
module Select2Helpers
  # Select an option from a Select2 dropdown
  def select2_select(option, from:)
    label = find("label", text: from, match: :prefer_exact)
    select_id = label[:for]

    container = if select_id
                  find("##{select_id}").find(:xpath, "..").find(".select2-container", match: :first)
                else
                  label.find(:xpath, "..").find(".select2-container", match: :first)
                end

    container.click

    within(".select2-dropdown") do
      find(".select2-results__option", text: option, match: :prefer_exact).click
    end
  end

  # Clear all selections from a Select2
  def select2_clear(field)
    label = find("label", text: field, match: :prefer_exact)
    select_id = label[:for]

    container = if select_id
                  find("##{select_id}").find(:xpath, "..").find(".select2-container", match: :first)
                else
                  label.find(:xpath, "..").find(".select2-container", match: :first)
                end

    return unless container.has_css?(".select2-selection__clear")

    container.find(".select2-selection__clear").click
  end

  # Check if a Select2 has a specific selection - returns a custom matcher
  # rubocop:disable Naming/PredicatePrefix
  def have_select2_selection(field, option)
    HaveSelect2Selection.new(field, option)
  end
  # rubocop:enable Naming/PredicatePrefix
end

# Custom RSpec matcher for Select2 selections
class HaveSelect2Selection
  def initialize(field, option)
    @field = field
    @option = option
  end

  def matches?(page)
    @page = page
    label = page.find("label", text: @field, match: :prefer_exact)
    select_id = label[:for]

    container = if select_id
                  page.find("##{select_id}").find(:xpath, "..").find(".select2-container", match: :first)
                else
                  label.find(:xpath, "..").find(".select2-container", match: :first)
                end

    container.has_css?(".select2-selection__choice", text: @option) ||
      container.has_css?(".select2-selection__rendered", text: @option)
  end

  def failure_message
    "expected Select2 '#{@field}' to have '#{@option}' selected"
  end

  def failure_message_when_negated
    "expected Select2 '#{@field}' not to have '#{@option}' selected"
  end
end

World(Select2Helpers)
