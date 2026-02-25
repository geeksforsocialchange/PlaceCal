# frozen_string_literal: true

class HelpAddingEvents < ViewComponent::Base
  include SvgImagesHelper

  def initialize(site)
    super()
    @site = site
  end
end
