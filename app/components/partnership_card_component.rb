# frozen_string_literal: true

class PartnershipCardComponent < ViewComponent::Base
  def initialize(site:)
    super
    url_concatenator = site.url[-1] == '/' ? '' : '/'
    @site_name = site.name
    @site_tagline = site.tagline
    @image_src = site.logo.url
    @link_to = "#{site.url}#{url_concatenator}events"
  end
end
