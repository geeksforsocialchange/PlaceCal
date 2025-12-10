# frozen_string_literal: true

# Helpers for Select2 dropdown interactions in system specs
module Select2Helpers
  def select2(value, options = {})
    raise 'Must pass a hash containing :from' unless options.is_a?(Hash) && options.key?(:from)

    container = find(:css, options[:from])
    container.click

    within('.select2-dropdown') do
      find('.select2-results__option', text: value).click
    end
  end

  def select2_ajax(value, options = {})
    raise 'Must pass a hash containing :from' unless options.is_a?(Hash) && options.key?(:from)

    container = find(:css, options[:from])
    container.click

    within('.select2-dropdown') do
      find('.select2-search__field').set(value)
      sleep 0.5 # Wait for AJAX
      find('.select2-results__option', text: value).click
    end
  end
end

RSpec.configure do |config|
  config.include Select2Helpers, type: :system
  config.include Select2Helpers, type: :feature
end
