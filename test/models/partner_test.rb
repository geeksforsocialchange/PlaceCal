# frozen_string_literal: true

require 'test_helper'

class PartnerTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @new_address = create(:address)
    @new_partner = build(:partner, address: @new_address, accessed_by_user: @user)
  end

  test 'updates user roles when saved' do
    @new_partner.users << @user
    @new_partner.save
    assert_predicate @user, :partner_admin?
  end

  test 'can change postcode of partner' do
    @new_partner.save!

    new_postcode = 'OL6 8BH'
    new_params = {
      address_attributes: {
        street_address: @new_address.street_address,
        postcode: new_postcode
      }
    }

    @new_partner.update! new_params
    @new_partner.reload

    assert_equal @new_partner.address.postcode, new_postcode
  end

  test 'it creates a new address even if the address matches an existing address' do
    @new_partner.save!

    other_partner = build(:partner, address: nil, accessed_by_user: @user)
    other_params = {
      address_attributes: {
        street_address: @new_address.street_address,
        postcode: @new_address.postcode
      }
    }
    other_partner.update! other_params
    other_partner.reload

    assert_not_equal @new_partner.address_id, other_partner.address_id, 'should have different address IDs'
  end

  test 'does not create an address object when address fields are blank' do
    root = create(:root)
    partner = build(:partner, address: nil, accessed_by_user: root)

    other_params = {
      address_attributes: {
        street_address: '',
        postcode: ''
      }
    }
    partner.service_areas.build neighbourhood: create(:bare_neighbourhood)
    partner.save!(**other_params)
    partner.reload

    assert_predicate partner.address, :blank?
  end

  test 'validate name length' do
    @new_partner.update(name: '1234')

    assert error_map = @new_partner.errors.where(:name, :too_short).first
    assert_equal 'must be at least 5 characters long', error_map.options[:message]
    assert_equal 1, @new_partner.errors.attribute_names.length
  end

  test 'validate uniqueness' do
    other_partner = Partner.create(name: 'Alpha Name', address: @new_partner.address, accessed_by_user: @user)

    # Name must be unique
    @new_partner.update(name: other_partner.name)
    assert_equal ['has already been taken'], @new_partner.errors[:name]
  end

  test 'validate no summary or description' do
    @new_partner.update(name: 'Test Partner', summary: '', description: '')
    assert_empty @new_partner.errors
  end

  test 'validate summary without description' do
    @new_partner.update(name: 'Test Partner', summary: 'This is a test partner used for testing :)', description: '')
    assert_empty @new_partner.errors, 'Should be able to submit a summary'
  end

  test 'validate description without summary' do
    @new_partner.update(
      name: 'Test Partner',
      description: 'This is a test partner used for testing :)',
      summary: ''
    )
    assert_equal ['cannot have a description without a summary'],
                 @new_partner.errors[:summary],
                 'Should not be able to have a description without summary'
  end

  test 'validate description and summary' do
    @new_partner.update(name: 'Test Partner',
                        summary: 'This is a test summary wheee :)',
                        description: 'This is a test new_partner used for testing :)')
    assert_empty @new_partner.errors, 'Should be able to submit a summary and description'
  end

  test 'validate summary length' do
    # We can submit a 200 character summary
    @new_partner.update(name: 'Test Partner', summary: ''.ljust(200, 'a'))
    assert_empty @new_partner.errors, '200 character summary should be valid'

    # But not a 201 character summary
    @new_partner.update(name: 'Test Partner', summary: ''.ljust(201, 'a'))
    assert @new_partner.errors.key?(:summary), 'maximum length is 200 characters'
  end

  test 'validate url' do
    # Url must be valid
    @new_partner.update(url: 'htp://bad-domain.co')
    assert_equal ['is invalid'], @new_partner.errors[:url], 'Partner must have a valid url'
    @new_partner.update(url: 'https://good-domain.com')
    assert_not @new_partner.errors.key?(:url), 'Valid URL not saved'
  end

  test 'validate twitter' do
    # Twitter must be valid
    @new_partner.update(twitter_handle: '@asdf')
    assert_not @new_partner.errors.key?(:twitter_handle), 'Valid twitter not saved'
    @new_partner.update(twitter_handle: 'asdf')
    assert_not @new_partner.errors.key?(:twitter_handle), 'Valid twitter not saved'
    @new_partner.update(twitter_handle: 'https://twitter.com/asdf')
    assert @new_partner.errors.key?(:twitter_handle), 'Should be account name not full URL'
    @new_partner.update(twitter_handle: 'asd£$%dsa')
    assert @new_partner.errors.key?(:twitter_handle), 'Invalid Twitter account name saved'
  end

  test 'validate facebook' do
    # Facebook must be valid
    @new_partner.update(facebook_link: 'https://facebook.com/group-name')
    assert @new_partner.errors.key?(:facebook_link), 'Should be page name not full URL'
    @new_partner.update(facebook_link: 'Group-Name')
    assert @new_partner.errors.key?(:facebook_link), 'invalid Facebook page name saved'
    @new_partner.update(facebook_link: 'GroupName')
    assert_not @new_partner.errors.key?(:facebook_link), 'Valid page name not saved'
  end

  test 'deals with badly formatted opening times' do
    partner = build(:partner)
    partner.opening_times = '{{ $data.openingHoursSpecifications }}'

    assert_empty partner.human_readable_opening_times
  end

  test 'opening_times can be unset' do
    p = Partner.new
    assert_equal '[]', p.opening_times_data

    p = Partner.new opening_times: ''
    assert_equal '[]', p.opening_times_data

    opening_times_payload = [
      { opens: '', closes: '' },
      { opens: '', closes: '' },
      { opens: '', closes: '' }
    ].to_json

    p = Partner.new(opening_times: opening_times_payload)

    found = JSON.parse(p.opening_times_data)
    assert_equal 3, found.length
  end

  test 'catches when a partner has their service areas and address removed' do
    partner = create(:partner)
    assert_predicate partner, :valid?

    partner.service_areas.destroy_all
    partner.address = nil

    assert_not partner.valid?

    problems = partner.errors[:base]
    assert_equal 'Partners must have at least one of service area or address', problems.first
  end

  test 'partner can have up to 3 "Category" tags' do
    partner = create(:partner)
    assert_predicate partner, :valid?

    partner.tags << create(:tag, type: 'Category', name: 'Category Tag 1')
    partner.tags << create(:tag, type: 'Category', name: 'Category Tag 2')
    partner.tags << create(:tag, type: 'Category', name: 'Category Tag 3')
    partner.save

    assert_predicate partner, :valid?
  end

  test 'partner cannot have more than 3 "Category" tags' do
    partner = create(:partner)
    assert_predicate partner, :valid?

    partner.tags << create(:tag, type: 'Category', name: 'Category Tag 1')
    partner.tags << create(:tag, type: 'Category', name: 'Category Tag 2')
    partner.tags << create(:tag, type: 'Category', name: 'Category Tag 3')
    partner.tags << create(:tag, type: 'Category', name: 'Category Tag 4')
    partner.save

    problems = partner.errors[:base]
    assert_equal 'Partner.tags can contain a maximum of 3 Category tags', problems.first
  end

  test 'partner has "Category" single table inheritance' do
    partner = create(:partner)
    assert_predicate partner, :valid?
    partner.tags << create(:tag, type: 'Category', name: 'Category Tag 1')
    partner.save
    assert_equal 1, partner.categories.count
  end

  test 'partner has "Facility" single table inheritance' do
    partner = create(:partner)
    assert_predicate partner, :valid?
    partner.tags << create(:tag, type: 'Facility', name: 'Facility Tag 1')
    partner.save
    assert_equal 1, partner.facilities.count
  end

  test 'partner has "Partnership" single table inheritance' do
    partner = create(:partner)
    assert_predicate partner, :valid?
    partner.tags << create(:partnership)
    partner.save
    assert_equal 1, partner.partnerships.count
  end

  test '#neighbourhood_name_for_site returns ward level neighbourhood name' do
    partner = create(:ashton_partner)
    name = partner.neighbourhood_name_for_site('ward')

    assert_equal('Ashton Hurst', name)
  end

  test '#neighbourhood_name_for_site returns district level neighbourhood name' do
    partner = create(:ashton_partner)
    partner.address.neighbourhood.parent = create(:neighbourhood_district)
    name = partner.neighbourhood_name_for_site('district')

    assert_equal('Manchester', name)
  end

  test '#neighbourhood_name_for_site returns service area name' do
    partner = create(:ashton_service_area_partner)
    name = partner.neighbourhood_name_for_site('ward')

    assert_equal('Ashton Hurst', name)
  end

  test '#self.neighbourhood_names_for_site returns names of partners for site' do
    site = create(:site)
    partner = create(:ashton_partner)
    site.neighbourhoods << partner.address.neighbourhood

    site_names = Partner.neighbourhood_names_for_site(site, 'ward')

    assert_equal(['Ashton Hurst'], site_names)
  end

  test '#self.neighbourhood_names_for_site returns district level names of partners for site' do
    site = create(:site)
    partner = create(:ashton_partner)
    partner.address.neighbourhood.parent = create(:neighbourhood_district)
    site.neighbourhoods << partner.address.neighbourhood

    site_names = Partner.neighbourhood_names_for_site(site, 'district')

    assert_equal(['Manchester'], site_names)
  end

  test '#self.neighbourhood_names_for_site returns names of partners service areas for site' do
    site = create(:site)
    partner = create(:ashton_service_area_partner)
    site.neighbourhoods << partner.address.neighbourhood

    site_names = Partner.neighbourhood_names_for_site(site, 'ward')

    assert_equal(['Ashton Hurst'], site_names)
  end

  test '#self.for_neighbourhood_name_filter returns partners restricted by site name' do
    partner_with_selected_neighbourhood = create(:ashton_partner)
    partner_with_selected_service_area = create(:ashton_service_area_partner)
    unselected_partner = create(:moss_side_partner)

    partners = Partner.for_neighbourhood_name_filter(Partner.all, 'ward', 'Ashton Hurst')

    assert_includes partners, partner_with_selected_neighbourhood
    assert_includes partners, partner_with_selected_service_area
    assert_not_includes partners, unselected_partner
  end

  test '#self.for_neighbourhood_name_filter returns partners restricted by site name at district level' do
    district = create(:neighbourhood_district)

    partner_with_selected_neighbourhood = create(:ashton_partner)
    partner_with_selected_service_area = create(:moss_side_partner)
    unselected_partner = create(:moss_side_partner)

    partner_with_selected_neighbourhood.address.neighbourhood.parent = district
    partner_with_selected_service_area.service_area_neighbourhoods = [district]

    all_partners = [
      partner_with_selected_neighbourhood,
      partner_with_selected_service_area,
      unselected_partner
    ]

    partners = Partner.for_neighbourhood_name_filter(all_partners, 'district', 'Manchester')

    assert_includes partners, partner_with_selected_neighbourhood
    assert_includes partners, partner_with_selected_service_area
    assert_not_includes partners, unselected_partner
  end

  #
  # testing how a user can assign an address (neighbourhood) to a partner
  #

  test 'NA admins can update partners outside of the neighbourhood pool (but not their address)' do
    # given a partner with an address not in the users' set
    # user can update other fields fine, but not change address.

    Neighbourhood.destroy_all
    a_neighbourhood = create(:bare_neighbourhood, name: 'alpha')

    # build a neighbourhood admin
    citizen_neighbourhood = create(:bare_neighbourhood, name: 'citizen alpha')
    citizen = create(:citizen)
    citizen.neighbourhoods << citizen_neighbourhood
    assert_predicate citizen, :valid?

    # build a partner NOT in the users set
    partner = build(:bare_partner, address: nil)
    partner.service_area_neighbourhoods << a_neighbourhood
    partner.save!

    # non-neighbourhood admin can update fields on partner okay
    partner.accessed_by_user = citizen
    partner.name = 'A different name'
    partner.save!

    # but cannot change the address to something they don't own
    b_neighbourhood = create(:bare_neighbourhood, name: 'beta', unit_code_value: 'E05011368')
    partner.accessed_by_user = citizen
    partner.address = build(:address, neighbourhood: b_neighbourhood)

    assert_not partner.valid?
    assert_predicate partner.errors[:base], :present?

    msg = partner.errors[:base].first
    assert_equal 'Partners cannot have an address outside of your ward.', msg
  end

  test 'NA can create a partner in their neighbourhood' do
    # given a user has a neighbourhood and let the user assign that neighbourhood to a new partner
    # this should be allowed (creating partners in their neighbourhoods)

    Neighbourhood.destroy_all

    a_neighbourhood = create(:bare_neighbourhood, name: 'beta', unit_code_value: 'E05011368')

    citizen = create(:citizen)
    citizen.neighbourhoods << a_neighbourhood

    assert_predicate citizen, :valid?

    address = build(:address)
    address.postcode = 'M15 5DD'

    assert citizen.assigned_to_postcode?(address.postcode)

    partner = build(:bare_partner, address: address)
    partner.accessed_by_user = citizen
    partner.save!
  end

  test 'users can change partner addresses to addresses they have neighbourhoods for' do
    # given a user with a neighbourhood and a partner with an address NOT in that neighbourhood
    # then that user should be able to assign their neighbourhood to that partners address

    Neighbourhood.destroy_all

    a_neighbourhood = create(:neighbourhood, unit_code_value: 'E05011368')
    b_neighbourhood = create(:neighbourhood, unit_code_value: 'E05011111')

    citizen = create(:citizen)
    citizen.neighbourhoods << b_neighbourhood
    assert_predicate citizen, :valid?

    # partners address NOT in citizens neighbourhood pool
    address = create(:address, neighbourhood: b_neighbourhood)
    partner = create(:partner, address: address)
    assert_predicate partner, :valid?

    partner.accessed_by_user = citizen
    partner.address.postcode = 'M15 5DD'
    partner.update! name: 'A new partner name'
  end

  test 'partnership_admin cannot create a partner that is not part of their partnership' do
    pa = create(:partnership_admin)
    assert_raises(ActiveRecord::RecordInvalid, 'This partner must be a part of your partnership') do
      create(:partner, :accessed_by_user => pa)
    end
  end

  test 'partnership_admin can create a partner that is part of their partnership' do
    pa = create(:partnership_admin)
    partner = create(:partner, :accessed_by_user => pa, :tags => [pa.tags.first])
    assert_predicate partner, :valid?
  end

  test 'can_clear_address?' do
    partner = Partner.new
    assert_not partner.can_clear_address?

    partner.address = create(:address)
    assert_not partner.can_clear_address?

    partner.service_areas.build(neighbourhood: create(:neighbourhood))
    assert_not partner.can_clear_address?

    root = create(:root)
    assert partner.can_clear_address?(root)
  end
end
