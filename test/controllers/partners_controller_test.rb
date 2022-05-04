# frozen_string_literal: true

require 'test_helper'

class PartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Make six partners: Two managers; two event hosts; two neither.
    # Add all to the default site and one of each category to a second site.

    neighbourhoods = [create(:neighbourhood), create(:neighbourhood)]
    # Deliberately saving address twice. (create + save) Second time overwrites neighbourhood.
    addresses = neighbourhoods.map do |n|
      a = create(:address)
      a.neighbourhood = n
      a.save
      a
    end
    @partners = addresses.map do |a|
      3.times.map { pa = build(:partner); pa.address = a; pa.save; pa }
    end
    @partners.each do |for_nbd|
      o_r = OrganisationRelationship.new
      o_r.subject = for_nbd[0]; o_r.verb = :manages; o_r.object = for_nbd[1]; o_r.save
      e = build(:event); e.dtstart = Date.today; e.place = for_nbd[2]; e.save
      for_nbd
    end
    default_site = create_default_site
    default_site.neighbourhoods.append(neighbourhoods)
    default_site.save
    @site = build(:site)
    @site.neighbourhoods.append(neighbourhoods.first)
    @site.save
  end

  test 'should get index without subdomain' do
    get url_for controller: "partners", subdomain: false
    assert_response :success

    assert_select "ul.partners li", 6
  end

  # test 'should get places_index without subdomain' do
  #   get url_for action: 'places_index', controller: "partners", subdomain: false
  #   assert_response :success
  #   assert_select "ul.places li", 2
  # end

  test 'should get index with configured subdomain' do
    get url_for controller: "partners", subdomain: @site.slug
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
    get partner_url(@partners.first.first)
    assert_response :success
  end

  test 'should show partner without address' do
    partner = create(:partner)
    partner.service_areas.create(neighbourhood: create(:neighbourhood))
    partner.address_id = nil
    partner.save!

    # Choose a manager to show. That will exercise more of the markup.
    get partner_url(partner)
    assert_response :success
  end

  test 'should show events with no place or address' do
    calendar = create(:calendar, strategy: 'no_location')
    partner = create(:partner)

    3.times do |n|
      partner.events.create!(
        calendar: calendar,
        summary: "Event #{n}",
        description: 'A description',
        dtstart: Time.now
      )
    end

    get partner_url(partner)

    events = assigns(:events).values.first
    assert events.length == 3
  end
end
