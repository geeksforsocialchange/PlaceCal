# frozen_string_literal: true

class LinkBtnLrgLightComponent < ViewComponent::Base
  def initialize(link_url:)
    super
    @link_url = link_url
  end
end
