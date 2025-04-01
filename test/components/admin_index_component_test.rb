# frozen_string_literal: true

require 'test_helper'
require 'view_component/test_case'

class AdminIndexComponentTest < ViewComponent::TestCase
  setup do
    @title = 'Hello World'
    @collection = create(:collection)
    @new_link = 'https://example.com'
    @column_titles = %w[ID Name Description]
    @columns = %i[id name description]
    @additional_links = ['https://real.demo.org']
  end

  def test_component_renders_admin_component
    render_inline(AdminIndexComponent.new(
                    title: @title, model: @collection, columns: @columns,
                    new_link: @new_link, column_titles: @column_titles,
                    additional_links: @additional_links, data: @collection
                  ))
    assert_text 'https://example.com'
  end
end
