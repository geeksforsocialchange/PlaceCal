# frozen_string_literal: true

require 'test_helper'

class PartnersIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Create a default site and a neighbourhood one
    @slugless_site = create_default_site

    @default_site = create(:site)
    @neighbourhood_site = create(:site_local)
    @region_site = create(:site_local)
    @tagged_site = create(:site_local)

    # Create one set of partners for the default site
    @default_site_partners = create_list(:partner, 5)
    @default_site_partners.each do |partner|
      next if @default_site.neighbourhoods.include? partner.address.neighbourhood

      @default_site.neighbourhoods << partner.address.neighbourhood
    end

    # Create another set for the neighbourhood site
    @neighbourhood_site_partners = create_list(:partner, 5)
    @neighbourhood2 = create(:neighbourhood)
    @neighbourhood_site_partners.each do |partner|
      partner.address.update(neighbourhood: @neighbourhood2)
    end
    @neighbourhood_site.neighbourhoods << @neighbourhood2

    # Set up a site bound to a region, and partners bound to a region descendant
    @region_site_partners = create_list(:partner, 5)
    @neighbourhood3 = create(:neighbourhood)
    @region_site_partners.each do |partner|
      partner.address.update(neighbourhood: @neighbourhood3)
    end
    @region_site.neighbourhoods << @neighbourhood3.region

    # Create a region site, with partners bound similarily, and then tag one of them
    @tagged_site_partners = create_list(:partner, 5)
    @neighbourhood4 = create(:neighbourhood)
    @tagged_site_partners.each do |partner|
      partner.address.update(neighbourhood: @neighbourhood4)
    end
    @tagged_site.neighbourhoods << @neighbourhood4

    @tag = create(:tag)
    @tagged_site.tags << @tag

    @tagged_site_partners.each do |partner|
      partner.tags << @tag
    end
  end

  test 'no slug redirects to find my placecal' do
    get partners_url
    assert_response :redirect
  end

  test 'placecal partners page shows all partners and relevant local info' do
    get from_site_slug(@default_site, partners_path)
    assert_response :success
    assert_select 'title', count: 1, text: "Partners in your area | #{@default_site.name}"
    assert_select 'div.hero h4', text: 'The Community Calendar'
    assert_select 'div.hero h1', text: 'Partners in your area'
    assert_select 'ul.partners li', 5
    # Ensure title/summary description is displayed
    assert_select '.preview__header', text: @default_site_partners.first.name
    assert_select '.preview__details', text: @default_site_partners.first.summary
  end

  test 'neighbourhood site page shows all partners and relevant local info' do
    get from_site_slug(@neighbourhood_site, partners_path)
    assert_response :success
    assert_select 'title', count: 1, text: "Partners in your area | #{@neighbourhood_site.name}"
    assert_select 'div.hero h4', text: "Neighbourhood's Community Calendar"
    assert_select 'div.hero h1', text: 'Partners in your area'
    assert_select 'ul.partners li', 5
    # Ensure title/summary description is displayed
    assert_select '.preview__header', text: @neighbourhood_site_partners.first.name
    assert_select '.preview__details', text: @neighbourhood_site_partners.first.summary
  end

  test 'region site page shows descendent partners' do
    get from_site_slug(@region_site, partners_path)
    assert_response :success
    assert_select 'title', count: 1, text: "Partners in your area | #{@region_site.name}"
    assert_select 'div.hero h4', text: "Neighbourhood's Community Calendar"
    assert_select 'div.hero h1', text: 'Partners in your area'
    assert_select 'ul.partners li', 5
    # Ensure title/summary description is displayed (select the h3 tag to avoid badge selection)
    assert_select 'div.preview__header h3', text: @region_site_partners.first.name
    assert_select 'div.preview__details', text: @region_site_partners.first.summary
  end

  test 'tagged site page shows only tagged partners' do
    get from_site_slug(@tagged_site, partners_path)
    assert_response :success

    assert_select 'title', count: 1, text: "Partners in your area | #{@tagged_site.name}"
    assert_select 'div.hero h4', text: "Neighbourhood's Community Calendar"
    assert_select 'div.hero h1', text: 'Partners in your area'
    assert_select 'ul.partners li', 1
    # Ensure title/summary description is displayed
    assert_select '.preview__header', text: @tagged_site_partners.first.name
    assert_select '.preview__details', text: @tagged_site_partners.first.summary
  end

  test 'partner shows service area if available' do
    partner = @default_site_partners.first
    partner.service_areas.create! neighbourhood: @neighbourhood3

    get from_site_slug(@default_site, partners_path)
    assert_response :success

    assert_select '.service-area span', text: @neighbourhood3.shortname
  end

  test 'partner shows "various areas" if more than one service area present' do
    partner = @default_site_partners.first
    partner.service_areas.create! neighbourhood: @neighbourhood3
    partner.service_areas.create! neighbourhood: @neighbourhood2

    get from_site_slug(@default_site, partners_path)
    assert_response :success

    assert_select '.service-area span', text: 'various'
  end
end
