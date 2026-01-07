# frozen_string_literal: true

# Step definitions for enhanced select box interactions (Tom Select)
# These select boxes create overlay elements that require special handling

# Select a single option from a searchable drop down select box
When("I select {string} from the {string} drop down select box") do |option, field|
  tom_select_select(option, from: field)
end

# Select from the service area drop down (nested Cocoon field)
When("I select {string} from the service area drop down select box") do |option|
  # Find the most recently added service area field
  within(".sites_neighbourhoods") do
    container = find(".ts-wrapper", match: :first)
    container.click
  end

  # Wait for dropdown and select option
  within(".ts-dropdown") do
    find(".option", text: option, match: :prefer_exact).click
  end
end

# Select multiple options from a searchable drop down select box
When("I select {string} and {string} from the {string} drop down select box") do |option1, option2, field|
  tom_select_select(option1, from: field)
  tom_select_select(option2, from: field)
end

# Clear all selections from a searchable drop down
When("I clear the {string} drop down select box") do |field|
  tom_select_clear(field)
end

# Verify a drop down select box has a specific option selected
Then("the {string} drop down select box should have {string} selected") do |field, option|
  expect(page).to have_tom_select_selection(field, option)
end

# Verify a drop down select box does not have a specific option selected
Then("the {string} drop down select box should not have {string} selected") do |field, option|
  expect(page).not_to have_tom_select_selection(field, option)
end

# Helper methods for Tom Select interactions
module TomSelectHelpers
  # Select an option from a Tom Select dropdown
  def tom_select_select(option, from:)
    label = find("label", text: from, match: :prefer_exact)

    # Tom Select modifies the label's for attribute to point to the control
    # e.g., partner_category_ids becomes partner_category_ids-ts-control
    # We need to find the ts-wrapper within the label's parent form-group
    form_group = label.find(:xpath, "ancestor::div[contains(@class, 'form-group')]")
    container = form_group.find(".ts-wrapper", match: :first)

    # Click the control to open the dropdown
    container.find(".ts-control").click

    # Wait for dropdown to appear and select option
    # Tom Select renders the dropdown inside the wrapper
    within(container) do
      find(".ts-dropdown .option", text: option, match: :prefer_exact).click
    end
  end

  # Clear all selections from a Tom Select
  def tom_select_clear(field)
    label = find("label", text: field, match: :prefer_exact)
    form_group = label.find(:xpath, "ancestor::div[contains(@class, 'form-group')]")
    container = form_group.find(".ts-wrapper", match: :first)

    # Tom Select uses .clear-button for clearing
    return unless container.has_css?(".clear-button")

    container.find(".clear-button").click
  end

  # Check if a Tom Select has a specific selection - returns a custom matcher
  # rubocop:disable Naming/PredicatePrefix
  def have_tom_select_selection(field, option)
    HaveTomSelectSelection.new(field, option)
  end
  # rubocop:enable Naming/PredicatePrefix
end

# Custom RSpec matcher for Tom Select selections
class HaveTomSelectSelection
  def initialize(field, option)
    @field = field
    @option = option
  end

  def matches?(page)
    @page = page
    label = page.find("label", text: @field, match: :prefer_exact)
    form_group = label.find(:xpath, "ancestor::div[contains(@class, 'form-group')]")
    container = form_group.find(".ts-wrapper", match: :first)

    # Tom Select uses .item for multi-select choices and shows text in ts-control for single select
    container.has_css?(".item", text: @option) ||
      container.has_css?(".ts-control", text: @option)
  end

  def failure_message
    "expected Tom Select '#{@field}' to have '#{@option}' selected"
  end

  def failure_message_when_negated
    "expected Tom Select '#{@field}' not to have '#{@option}' selected"
  end
end

World(TomSelectHelpers)
