# frozen_string_literal: true

require 'test_helper'

class TagFilterTest < ActiveSupport::TestCase
  class FakeView
    include ActionView::Helpers::FormOptionsHelper
    include ActionView::Helpers::UrlHelper
    include Rails.application.routes.url_helpers

    def controller
      :tags_controller
    end

    def action
      :index
    end
  end

  test 'instantiates' do
    filter = TagFilter.new({})
    assert filter.is_a?(TagFilter)
  end

  test '#with_scope by type' do
    create :tag, type: 'Facility', name: 'Facility Tag 1'
    create :tag, type: 'Facility', name: 'Facility Tag 2'
    create :tag, type: 'Partnership', name: 'Partnership Tag 1'
    create :tag, type: 'Partnership', name: 'Partnership Tag 2'
    create :tag, type: 'Partnership', name: 'Partnership Tag 3'

    # find by type
    params = {
      type: 'facility'
    }
    filter = TagFilter.new(params)
    found = filter.with_scope(Tag)

    assert_equal 2, found.count, 'Should only find Facility tags'
  end

  test '#with_scope ignores invalid types' do
    create :tag, type: 'Facility', name: 'Facility Tag'
    create :tag, type: 'Partnership', name: 'Partnership Tag'

    # find by type
    params = {
      type: 'alpha'
    }
    filter = TagFilter.new(params)
    found = filter.with_scope(Tag)

    assert_equal 2, found.count, 'Should find all tags'
  end

  test '#with_scope by name' do
    # find by name
    create :tag, type: 'Facility',    name: 'Facility Bark Tag A'
    create :tag, type: 'Partnership', name: 'Partnership Bark Tag B'
    create :tag, type: 'Facility',    name: 'Facility Bark Tag C'
    create :tag, type: 'Partnership', name: 'Partnership Bark Tag D'

    params = {
      name: 'bark' # is case insensitive
    }
    filter = TagFilter.new(params)
    found = filter.with_scope(Tag)

    assert_equal 4, found.count, 'Should only find Bark tags'
  end

  test '#with_window limit' do
    create_list :tag, 100

    filter = TagFilter.new({})
    found = filter.with_window(Tag)

    assert_equal 10, found.count, 'Should be 10 by default'

    params = {
      per_page: '20'
    }
    filter = TagFilter.new(params)
    found = filter.with_window(Tag)

    assert_equal 20, found.count, 'Should be 20'

    params = {
      per_page: '50'
    }
    filter = TagFilter.new(params)
    found = filter.with_window(Tag)

    assert_equal 50, found.count, 'Should be 50'
  end

  test '#options_for_type' do
    params = {}
    filter = TagFilter.new(params)
    output = filter.options_for_type(FakeView.new)

    assert output.is_a?(String)

    expected_html =
      "<option value=\"\">All</option>\n" \
      "<option value=\"category\">Category</option>\n" \
      "<option value=\"facility\">Facility</option>\n" \
      '<option value="partnership">Partnership (Site)</option>'

    assert_equal output, expected_html

    # with selection
    params = { type: 'facility' }
    filter = TagFilter.new(params)
    output = filter.options_for_type(FakeView.new)

    assert output.is_a?(String)

    expected_html =
      "<option value=\"\">All</option>\n" \
      "<option value=\"category\">Category</option>\n" \
      "<option selected=\"selected\" value=\"facility\">Facility</option>\n" \
      '<option value="partnership">Partnership (Site)</option>'

    assert_equal output, expected_html
  end

  test '#options_for_per_page' do
    params = {}
    filter = TagFilter.new(params)
    output = filter.options_for_per_page(FakeView.new)

    assert output.is_a?(String)

    expected_html =
      "<option value=\"10\">10</option>\n" \
      "<option value=\"20\">20</option>\n" \
      '<option value="50">50</option>'

    assert_equal output, expected_html

    # with valid value
    params = { per_page: '20' }
    filter = TagFilter.new(params)
    output = filter.options_for_per_page(FakeView.new)

    assert output.is_a?(String)

    expected_html =
      "<option value=\"10\">10</option>\n" \
      "<option selected=\"selected\" value=\"20\">20</option>\n" \
      '<option value="50">50</option>'

    assert_equal output, expected_html
  end

  test '#next_page_link' do
    # renders placeholder text when no results found
    params = {}
    filter = TagFilter.new(params)
    scope = filter.with_window(Tag.all)

    output = filter.next_page_link(FakeView.new, scope)
    assert output.is_a?(String)

    expected_html = 'No more results available'
    assert_equal output, expected_html

    # now with tags
    create_list :tag, 25

    params = {}
    filter = TagFilter.new(params)
    scope = filter.with_window(Tag.all)

    output = filter.next_page_link(FakeView.new, scope)
    assert output.is_a?(String)

    expected_html = '<a class="btn btn-link" href="/tags?page_num=2">Next ...</a>'
    assert_equal output, expected_html

    # second page
    params = { page_num: '2' }
    filter = TagFilter.new(params)
    scope = filter.with_window(Tag.all)

    output = filter.next_page_link(FakeView.new, scope)
    assert output.is_a?(String)

    expected_html = '<a class="btn btn-link" href="/tags?page_num=3">Next ...</a>'
    assert_equal output, expected_html

    # last page
    params = { page_num: '3' }
    filter = TagFilter.new(params)
    scope = filter.with_window(Tag.all)

    output = filter.next_page_link(FakeView.new, scope)
    assert output.is_a?(String)

    expected_html = 'No more results available'
    assert_equal output, expected_html

    # carries through parameters from rest of filter
    params = {
      type: 'facility',
      name: 'alpha',
      per_page: '20',
      page_num: '2'
    }
    filter = TagFilter.new(params)

    output = filter.next_page_link(FakeView.new, Tag.all)
    assert output.is_a?(String)

    expected_html = '<a class="btn btn-link" href="/tags?name=alpha&page_num=3&per_page=20&type=facility">Next ...</a>'
    assert_equal output, expected_html
  end
end
