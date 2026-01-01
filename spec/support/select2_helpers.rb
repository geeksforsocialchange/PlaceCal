# frozen_string_literal: true

require "capybara-select-2"

# Helpers for Select2 dropdown interactions in system specs
module Select2Helpers
  include CapybaraSelect2
  include CapybaraSelect2::Helpers

  # Wait for select2 containers to be ready
  def await_select2(time = 30)
    find_element_with_retry do
      page.all(:css, ".select2-container", wait: time)
      expect(page).to have_selector(".select2-selection")
    end
  end

  # Find a select2 node by its stable CSS class identifier
  def select2_node(stable_identifier)
    await_select2(10)
    find_element_with_retry do
      within(".#{stable_identifier}") do
        find(:css, ".select2-container")
      end
    end
  end

  # Find all cocoon (nested form) select2 nodes
  def all_cocoon_select2_nodes(css_class)
    await_select2(10)
    within(".#{css_class}") do
      all(:css, ".select2-container")
    end
  end

  # Assert a single value is selected in select2
  def assert_select2_single(option, node)
    await_select2(10)
    within(:xpath, node.path) do
      expect(page).to have_selector(".select2-selection__rendered", text: option)
    end
  end

  # Assert multiple values are selected in select2
  def assert_select2_multiple(options_array, node)
    find_element_with_retry do
      within(:xpath, node.path) do
        expect(page).to have_selector(".select2-selection__choice", count: options_array.length)
        rendered = find(:css, ".select2-selection__rendered").text.delete("×").delete("\n")
        options_array.each do |opt|
          rendered = rendered.gsub(opt, "")
        end
        expect(rendered).to eq(""), "'#{rendered}' is in the selected data but not in the options passed to this test"
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
  config.include Select2Helpers, type: :system
  config.include Select2Helpers, type: :feature
end
