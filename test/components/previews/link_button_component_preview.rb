# frozen_string_literal: true

class LinkButtonComponentPreview < ViewComponent::Preview
  def default
    render(LinkButtonComponent.new(href: "#").with_content("Do something"))
  end
end
