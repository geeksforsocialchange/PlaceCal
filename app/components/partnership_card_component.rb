# frozen_string_literal: true

class PartnershipCardComponent < ViewComponent::Base
  def initialize(title:, logo_url:, link_url:, summary:)
    super
    @title = title
    @logo_url = logo_url
    @link_url = link_url
    @summary = summary
  end
end
