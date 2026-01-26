# frozen_string_literal: true

# Step definitions for enhanced select box interactions (Tom Select)
# These select boxes create overlay elements that require special handling

# Select a single option from a searchable drop down select box
When("I select {string} from the {string} drop down select box") do |option, field|
  tom_select_select(option, from: field)
end

# Select from the service area drop down (nested form field)
When("I select {string} from the service area drop down select box") do |option|
  # Wait for Stimulus nested-form controller to add the element
  sleep 0.5

  # Find the service area nested fields specifically
  # The address fields have data-controller="partner-address", service area fields don't
  # Look for all nested-fields and find the one that's NOT the address fields
  service_area_container = nil
  attempts = 0

  while service_area_container.nil? && attempts < 10
    all_nested = page.all(".nested-fields", wait: 2)
    service_area_container = all_nested.find do |el|
      el[:class].to_s.exclude?("partner-address") &&
        (el["data-controller"].nil? || el["data-controller"].to_s.empty? || el["data-controller"].exclude?("partner-address"))
    end
    sleep 0.5 if service_area_container.nil?
    attempts += 1
  end

  raise "Could not find service area container after #{attempts} attempts. Found #{page.all('.nested-fields').count} nested-fields elements." unless service_area_container

  # Check for Tom Select wrapper or native select
  if service_area_container.has_css?(".ts-wrapper", wait: 3)
    container = service_area_container.find(".ts-wrapper", match: :first)
    container.find(".ts-control").click
    dropdown = page.find(".ts-dropdown", visible: true, wait: 5)
    within(dropdown) do
      find(".option", text: option, match: :prefer_exact).click
    end
  elsif service_area_container.has_css?("select", wait: 1)
    within(service_area_container) do
      select_element = find("select", match: :first)
      select_element.select(option)
    end
  else
    raise "Could not find service area dropdown in container"
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
  # Select an option from a Tom Select dropdown or regular select
  def tom_select_select(option, from:)
    # Try finding by label first (standard form), then by legend (daisyUI fieldset)
    form_group = nil
    begin
      label = find("label", text: from, match: :prefer_exact)
      form_group = begin
        label.find(:xpath, "ancestor::div[contains(@class, 'form-group')]")
      rescue Capybara::ElementNotFound
        label.find(:xpath, "ancestor::div[contains(@class, 'mb-4')]")
      end
    rescue Capybara::ElementNotFound
      # Try finding by fieldset legend (daisyUI pattern)
      fieldset = find("fieldset", text: from, match: :prefer_exact)
      form_group = fieldset
    end

    # Check if this is a Tom Select or a regular select (e.g., partnership-selector)
    if form_group.has_css?(".ts-wrapper", wait: 2)
      # Tom Select - use the special handling
      container = form_group.find(".ts-wrapper", match: :first, wait: 5)

      # Click the control to open the dropdown
      control = container.find(".ts-control")
      control.click

      # Wait a moment for dropdown to render
      sleep 0.5

      # First try finding dropdown with standard visibility check
      # Then fall back to visible: :all since Capybara's visibility detection
      # can have issues with dynamically shown elements
      dropdown = nil
      begin
        dropdown = page.find(".ts-dropdown", visible: true, wait: 2)
      rescue Capybara::ElementNotFound
        # Capybara visibility detection can be unreliable for dynamically styled elements
        # If the dropdown has active styles, find it with visible: :all
        dropdowns = page.all(".ts-dropdown", visible: :all)
        dropdown = dropdowns.find { |d| d[:style]&.include?("display: block") }
      end

      raise "Tom Select dropdown not found" unless dropdown

      within(dropdown) do
        # Find option with visible: :all for same reason
        opt = all(".option", text: option, visible: :all, wait: 2).first
        raise "Option '#{option}' not found in dropdown" unless opt

        # Use JS click to avoid interactability issues with dynamically positioned elements
        page.execute_script("arguments[0].click()", opt)
      end
    elsif form_group.has_css?("select", wait: 2)
      # Regular select element (partnership-selector uses plain select with Stimulus)
      within(form_group) do
        find("select", match: :first).select(option)
      end
    else
      raise "Could not find select element in form group for '#{from}'"
    end
  end

  # Clear all selections from a Tom Select
  def tom_select_clear(field)
    label = find("label", text: field, match: :prefer_exact)
    form_group = begin
      label.find(:xpath, "ancestor::div[contains(@class, 'form-group')]")
    rescue Capybara::ElementNotFound
      label.find(:xpath, "ancestor::div[contains(@class, 'mb-4')]")
    end
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
    form_group = begin
      label.find(:xpath, "ancestor::div[contains(@class, 'form-group')]")
    rescue Capybara::ElementNotFound
      label.find(:xpath, "ancestor::div[contains(@class, 'mb-4')]")
    end
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
