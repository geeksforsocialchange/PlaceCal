# frozen_string_literal: true

class NeighbourhoodHomeCardComponent < ViewComponent::Base
  def initialize(site:)
    super
    @site = site
  end
end
