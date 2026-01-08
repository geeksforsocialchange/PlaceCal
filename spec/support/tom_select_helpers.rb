# frozen_string_literal: true

# Helpers for Tom Select dropdown interactions in system specs
module TomSelectHelpers
  # Wait for Tom Select containers to be ready
  def await_tom_select(time = 30)
    find_element_with_retry do
      page.all(:css, ".ts-wrapper", wait: time)
      expect(page).to have_selector(".ts-control")
    end
  end

  # Find a Tom Select node by its stable CSS class identifier
  def tom_select_node(stable_identifier)
    await_tom_select(10)
    find_element_with_retry do
      within(".#{stable_identifier}") do
        find(:css, ".ts-wrapper")
      end
    end
  end

  # Find all nested form (Cocoon replacement) Tom Select nodes
  def all_nested_form_tom_select_nodes(css_class)
    await_tom_select(10)
    within(".#{css_class}") do
      all(:css, ".ts-wrapper")
    end
  end

  # Select a value in a Tom Select dropdown
  # @param options [Array<String>] The option text(s) to select
  # @param xpath [String] The xpath of the Tom Select container
  def tom_select(*options, xpath:)
    within(:xpath, xpath) do
      # Click the control to open the dropdown
      find(".ts-control").click

      options.each do |option|
        # Type to search and find the option
        input = find(".ts-control input", visible: :all)
        input.set(option)
        sleep 0.2 # Allow search results to load

        # Click the matching option in the dropdown
        find(".ts-dropdown .option", text: option, match: :prefer_exact).click
      end

      # Close dropdown by clicking outside if it's still open
      find("body").click if has_selector?(".ts-dropdown", wait: 0.5)
    end
  end

  # Assert a single value is selected in Tom Select
  def assert_tom_select_single(option, node)
    await_tom_select(10)
    within(:xpath, node.path) do
      expect(page).to have_selector(".ts-control .item", text: option)
    end
  end

  # Assert multiple values are selected in Tom Select
  def assert_tom_select_multiple(options_array, node)
    find_element_with_retry do
      within(:xpath, node.path) do
        expect(page).to have_selector(".ts-control .item", count: options_array.length)
        options_array.each do |opt|
          expect(page).to have_selector(".ts-control .item", text: opt)
        end
      end
    end
  end

  # Retry helper for stale elements
  def find_element_and_retry_if_stale(max_attempts: 3, &)
    find_element_with_retry(max_attempts: max_attempts, &)
  end

  # Retry helper for not found elements
  def find_element_and_retry_if_not_found(max_attempts: 3, &)
    find_element_with_retry(max_attempts: max_attempts, &)
  end
end

RSpec.configure do |config|
  config.include TomSelectHelpers, type: :system
  config.include TomSelectHelpers, type: :feature
end
