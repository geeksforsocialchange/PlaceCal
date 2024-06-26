# frozen_string_literal: true

module Select2Helpers
  def await_select2(time = 30)
    find_element_and_retry_if_stale do
      page.all :css, '.select2-container', wait: time
      assert_selector '.select2-selection'
    end
  end

  def select2_node(stable_identifier)
    await_select2 10
    find_element_and_retry_if_stale do
      within ".#{stable_identifier}" do
        find :css, '.select2-container'
      end
    end
  end

  def all_cocoon_select2_nodes(css_class)
    await_select2 10
    within ".#{css_class}" do
      all :css, '.select2-container'
    end
  end

  def assert_select2_single(option, node)
    await_select2 10
    within :xpath, node.path do
      assert_selector '.select2-selection__rendered', text: option
    end
  end

  def assert_select2_multiple(options_array, node)
    # The data is stored like this.
    # "×Computer Access\n×Free WiFi\n×GM Systems Changers"
    # The order is unpredictable so we can't build version from our options to test against
    # instead copy the data, then pull out the options and joining characters
    # If we are left with nothing then the options and stored data match
    find_element_and_retry_if_stale do
      within :xpath, node.path do
        assert_selector '.select2-selection__choice', count: options_array.length
        rendered = find(:css, '.select2-selection__rendered').text.delete('×').delete("\n")
        options_array.each do |opt|
          rendered = rendered.gsub(opt, '')
        end
        assert_equal('', rendered, "'#{rendered}' is in the selected data but not in the options passed to this test")
      end
    end
  end
end
