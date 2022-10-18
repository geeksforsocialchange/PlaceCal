# frozen_string_literal: true

require 'test_helper'

class SiteTest < ActiveSupport::TestCase
  setup do
    @site = create(:site)
  end

  test 'gets correct stylesheet link' do
    assert_equal 'themes/pink', @site.stylesheet_link
    @site.theme = :custom
    @site.slug = 'my-town'
    assert_equal 'themes/custom/my-town', @site.stylesheet_link
    @site.slug = 'default-site'
    assert_equal 'home', @site.stylesheet_link
  end
end

class SitePartnerTest < ActiveSupport::TestCase
  test 'can find sites by partner' do
    address_neighbourhood = FactoryBot.create(:neighbourhood)
    service_area_neighbourhood = FactoryBot.create(:rusholme_neighbourhood)

    address = FactoryBot.create(:address, neighbourhood: address_neighbourhood)

    address_site = FactoryBot.create(:site, name: 'address site')
    address_site.neighbourhoods << address_neighbourhood

    service_area_site = FactoryBot.create(:site, name: 'service area site')
    service_area_site.neighbourhoods << service_area_neighbourhood

    tag = FactoryBot.create(:tag)
    tag_site = FactoryBot.create(:site, name: 'tag site')
    tag_site.tags << tag

    partner = FactoryBot.create(:partner)
    partner.address.neighbourhood = address_neighbourhood
    partner.service_area_neighbourhoods << service_area_neighbourhood
    partner.tags << tag

    service_area_site

    found = Site.sites_that_contain_partner(partner).order(:id)

    assert_equal found, [address_site, service_area_site, tag_site]
  end
end
