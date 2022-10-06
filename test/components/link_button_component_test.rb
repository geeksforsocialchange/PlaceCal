# frozen_string_literal: true

require "test_helper"

class LinkButtonComponentTest < ViewComponent::TestCase
  def test_component_renders_something_useful
    assert_equal(
      render_inline(LinkButtonComponent.new(href: "/path/to/test").with_content("Go to test!")).to_html,
      %(<a href="/path/to/test">Go to test!</a>),
    )
  end
end
