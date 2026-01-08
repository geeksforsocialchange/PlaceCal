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
  # @param association [String] The association name (e.g., "service_areas")
  #   This will look for the wrapper class "nested-form-{association}" with underscores replaced by hyphens
  def all_nested_form_tom_select_nodes(association)
    await_tom_select(10)
    css_class = "nested-form-#{association.to_s.tr('_', '-')}"
    within(".#{css_class}") do
      all(:css, ".ts-wrapper")
    end
  end

  # Select a value in a Tom Select dropdown
  # Uses JavaScript to directly interact with Tom Select for reliability
  # @param options [Array<String>] The option text(s) to select
  # @param xpath [String] The xpath of the Tom Select wrapper
  def tom_select(*options, xpath:)
    wrapper = find(:xpath, xpath)

    options.each do |option|
      # Scroll the element into view
      scroll_to(wrapper)
      sleep 0.1

      # Tom Select stores the instance on the original select element
      # The select is a sibling of .ts-wrapper, so look in the parent container
      # Use JavaScript to find the Tom Select instance from the wrapper
      result = page.evaluate_script(<<~JS)
        (function() {
          var wrapper = document.evaluate('#{xpath}', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
          if (!wrapper) return { error: 'Wrapper not found' };

          // The select element is a sibling of the wrapper
          var parent = wrapper.parentElement;
          var select = parent.querySelector('select');
          if (!select) return { error: 'Select not found in parent' };
          if (!select.tomselect) return { error: 'Tom Select not initialized on select' };

          var ts = select.tomselect;
          var opts = [];
          for (var key in ts.options) {
            var opt = ts.options[key];
            opts.push({ value: key, text: opt.text || opt.label || opt.name || key });
          }
          return { selectId: select.id, options: opts };
        })()
      JS

      raise Capybara::ElementNotFound, "Tom Select error: #{result['error']}" if result["error"]

      # Find the option that matches the text
      matching_option = result["options"].find { |o| o["text"]&.include?(option) }

      if matching_option.nil?
        option_texts = result["options"].map { |o| o["text"] }.join(", ")
        raise Capybara::ElementNotFound,
              "Option '#{option}' not found. Available: [#{option_texts}]"
      end

      # Use Tom Select API to add the item
      select_id = result["selectId"]
      page.execute_script(<<~JS)
        (function() {
          var select = document.getElementById('#{select_id}');
          if (select && select.tomselect) {
            select.tomselect.addItem('#{matching_option['value']}');
          }
        })()
      JS

      sleep 0.1
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
