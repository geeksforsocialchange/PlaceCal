# frozen_string_literal: true

class PartnershipCardComponent < ViewComponent::Base
  def initialize(site:)
    super
    url_concatenator = site.domain[-1] == '/' ? '' : '/'
    @site_name = site.name
    @site_tagline = site.tagline
    @image_src = site.logo.url
    @link_to = "#{site.domain}#{url_concatenator}events"
  end
end
