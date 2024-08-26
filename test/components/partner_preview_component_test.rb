# frozen_string_literal: true

require 'test_helper'

class PartnerPreviewComponentTest < ViewComponent::TestCase
  setup do
    @partner = create(:partner)
    @site = create(:site)
  end

  def test_component_renders_something_useful
    render_inline(PartnerPreviewComponent.new(partner: @partner, site: @site))

    assert_selector 'h3', text: @partner.name
    assert_selector 'p', text: @partner.summary
    assert_selector 'span', text: 'Hulme'
  end
end
