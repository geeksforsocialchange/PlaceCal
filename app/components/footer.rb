# frozen_string_literal: true

class Footer < ViewComponent::Base
  def initialize(site)
    super()
    @site = site
  end
end
