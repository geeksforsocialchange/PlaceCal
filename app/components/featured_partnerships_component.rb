# frozen_string_literal: true

class FeaturedPartnershipsComponent < ViewComponent::Base
  def initialize(sites:)
    super
    @sites = sites
  end
end
