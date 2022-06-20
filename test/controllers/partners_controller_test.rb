# frozen_string_literal: true

require 'test_helper'

class PartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Make six partners: Two managers; two event hosts; two neither.
    # Add all to the default site and one of each category to a second site.

    neighbourhoods = create_list(:neighbourhood, 2)

    # Deliberately saving address twice. (create + save) Second time overwrites neighbourhood.
    addresses = neighbourhoods.map do |n|
      a = create(:address)
      a.neighbourhood = n
      a.save
      a
    end
    # NOTE: Uhhh? What? Is this a factorybot thing? Why does create(:address, neighbourhood: n) not work here?

    @partners = addresses.map do |a|
      create_list(:partner, 3, address: a)
    end

    # NOTE: Uhhh, what does this do? - Alexandria, 2022-05-31
    @partners.each do |for_nbd|
      o_r = OrganisationRelationship.new
      o_r.subject = for_nbd[0]; o_r.verb = :manages; o_r.object = for_nbd[1]; o_r.save
      e = build(:event); e.dtstart = Date.today; e.place = for_nbd[2]; e.save
      for_nbd
    end

    @slugless_site = create_default_site

    @default_site = create(:site)
    @default_site.neighbourhoods.append(neighbourhoods)
    @default_site.save

    @site = build(:site)
    @site.neighbourhoods.append(neighbourhoods.first)
    @site.save
  end

  test 'should get index without subdomain' do
    get url_for controller: "partners", subdomain: false
    assert_response :redirect
  end

  # test 'should get places_index without subdomain' do
  #   get url_for action: 'places_index', controller: "partners", subdomain: false
  #   assert_response :success
  #   assert_select "ul.places li", 2
  # end

  test 'should get index with configured subdomain' do
    get from_site_slug(@site, partners_path)

    assert_response :success
    assert_select "ul.partners li", 3
  end

  # test 'should get places_index with configured subdomain' do
  #   get url_for action: 'places_index', controller: "partners", subdomain: @site.slug
  #   assert_response :success
  #   assert_select "ul.places li", 1
  # end

  test 'should redirect from index with unknown subdomain' do
    get url_for controller: "partners", subdomain: "notaknownsubdomain"
    assert_response :redirect
  end

  # test 'should redirect from places_index with unknown subdomain' do
  #   get url_for action: 'places_index', controller: "partners", subdomain: "notaknownsubdomain"
  #   assert_response :redirect
  # end

  test 'should show partner' do
    # Choose a manager to show. That will exercise more of the markup.
    get from_site_slug(@site, partner_path(@partners.first.first))
    assert_response :success
  end

  test 'should show partner without address' do
    partner = create(:partner)
    partner.service_areas.create(neighbourhood: create(:neighbourhood))
    partner.address_id = nil
    partner.save!

    # Choose a manager to show. That will exercise more of the markup.
    get from_site_slug(@site, partner_path(partner))
    assert_response :success
  end

  test 'should show events with no place or address' do
    calendar = create(:calendar, strategy: 'no_location')
    partner = create(:partner)

    partner.events += create_list(:event, 3, calendar: calendar, dtstart: Time.now)

    get from_site_slug(@site, partner_path(partner))

    events = assigns(:events).values.first
    assert events.length == 3
  end
end
