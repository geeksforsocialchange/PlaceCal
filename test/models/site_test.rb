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

class CustomDomainTest < ActiveSupport::TestCase
  # We could use webmock here but we're not actually simulating the HTTP part so we'll make a little mock struct
  MockRequest = Struct.new(:host) do
    def subdomains
      host.split('.')
    end

    def subdomain
      subdomains.first
    end
  end

  setup do
    @site = create(:site, url: 'https://wibble.example.com/', slug: 'wibblecal')
  end

  test 'site is returned for a request that has domain' do
    request = MockRequest.new('wibble.example.com')
    assert_equal Site.find_by_request(request), @site
  end

  test 'site is returned for slug' do
    request = MockRequest.new('wibblecal.placecal.org')
    assert_equal Site.find_by_request(request), @site
  end

  test 'site is returned for www.slug' do
    request = MockRequest.new('www.wibblecal.placecal.org')
    assert_equal Site.find_by_request(request), @site
  end

  test 'site is not returned for a request that has neither' do
    request = MockRequest.new('nothing.placecal.org')
    assert_not_equal Site.find_by_request(request), @site
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

    tag = FactoryBot.create(:partnership)
    tag_site = FactoryBot.create(:site, name: 'tag site')
    tag_site.tags << tag
    tag_site.neighbourhoods << address_neighbourhood

    partner = FactoryBot.create(:partner)
    partner.address.neighbourhood = address_neighbourhood
    partner.service_area_neighbourhoods << service_area_neighbourhood
    partner.tags << tag
    partner.save

    found = Site.sites_that_contain_partner(partner)

    assert_equal found, [address_site, service_area_site, tag_site]
  end
end
