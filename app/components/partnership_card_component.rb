# frozen_string_literal: true

class PartnershipCardComponent < ViewComponent::Base
  def initialize(site:)
    super
    @site = site
  end
end
