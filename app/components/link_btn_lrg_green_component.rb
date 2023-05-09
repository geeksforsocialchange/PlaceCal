# frozen_string_literal: true

class LinkBtnLrgGreenComponent < ViewComponent::Base
  def initialize(link_url:)
    super
    @link_url = link_url
  end
end
