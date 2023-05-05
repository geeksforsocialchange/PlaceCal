# frozen_string_literal: true

class FullWidthActionComponent < ViewComponent::Base
  def initialize(title:, link_text:, link_url:)
    super
    @title = title
    @link_text = link_text
    @link_url = link_url
  end
end
