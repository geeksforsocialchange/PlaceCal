# frozen_string_literal: true

require 'test_helper'

class PartnersIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Create a default site and a neighbourhood one
    @default_site = create_default_site
    @neighbourhood_site = create(:site_local)

    # Create one set of partners for the default site
    @default_site_partners = create_list :partner, 5
    @default_site_partners.each do |partner|
      next if @default_site.neighbourhoods.include? partner.address.neighbourhood

      @default_site.neighbourhoods << partner.address.neighbourhood
    end

    # Create another set for the neighbourhood site
    @neighbourhood_site_partners = create_list :partner, 5
    @neighbourhood2 = create(:neighbourhood)
    @neighbourhood_site_partners.each do |partner|
      partner.address.update(neighbourhood: @neighbourhood2)
    end
    @neighbourhood_site.neighbourhoods << @neighbourhood2
  end

  test 'placecal partners page shows all partners and relevant local info' do
    get partners_url
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
    get "http://#{@neighbourhood_site.slug}.lvh.me/partners"
    assert_response :success
    assert_select 'title', count: 1, text: "Partners in your area | #{@neighbourhood_site.name}"
    assert_select 'div.hero h4', text: "Neighbourhood's Community Calendar"
    assert_select 'div.hero h1', text: 'Partners in your area'
    assert_select 'ul.partners li', 5
    # Ensure title/summary description is displayed
    assert_select '.preview__header', text: @neighbourhood_site_partners.first.name
    assert_select '.preview__details', text: @neighbourhood_site_partners.first.summary
  end
end
