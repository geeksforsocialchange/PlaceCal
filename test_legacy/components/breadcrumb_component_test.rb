# frozen_string_literal: true

require 'test_helper'
require 'view_component/test_case'

class AddressComponentTest < ViewComponent::TestCase
  setup do
    # TODO: once we can make the event factory use a local calendar
    # instead of one that makes outgoing HTTP calls, switch to using
    # the event factory here. Or remove this TODO once
    # we have an integration test
    @address = create(:address)
    @site_name = 'Site name'
    @trail = [['First', '/first'], ['Second', '/second']]
  end

  def test_component_renders_address
    render_inline(BreadcrumbComponent.new(site_name: @site_name, trail: @trail))
    assert_text 'Site name'
    assert_text 'First'
    assert_text 'Second'
  end
end
