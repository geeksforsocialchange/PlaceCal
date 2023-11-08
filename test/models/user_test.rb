# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    create_typed_tags
    @user = create(:user)
    @neighbourhood_region_admin = create(:neighbourhood_region_admin)
  end

  test 'owned neighbourhoods returns all descendants' do
    # Does the admin only own one region neighbourhood?
    assert_equal(1, @neighbourhood_region_admin.neighbourhoods.length)
    assert_equal('region', @neighbourhood_region_admin.neighbourhoods.first.unit)

    # Does it return the region, the districts, and the wards?
    # We have five counties with one district each, all parenting one ward, plus the region
    # (See: factories/user.rb - neighbourhood_region_admin)
    owned_length = 1 + (5 * 3)
    assert_equal @neighbourhood_region_admin.owned_neighbourhoods.to_a.length, owned_length

    # does it actually return both the districts and the wards?
    assert_equal(5, @neighbourhood_region_admin.owned_neighbourhoods.count { |u| u.unit == 'county' })
    assert_equal(5, @neighbourhood_region_admin.owned_neighbourhoods.count { |u| u.unit == 'district' })
    assert_equal(5, @neighbourhood_region_admin.owned_neighbourhoods.count { |u| u.unit == 'ward' })
  end

  test 'can view neighourhoods assigned to them' do
    owned_neighbourhoods = @neighbourhood_region_admin.owned_neighbourhoods
    region = @neighbourhood_region_admin.neighbourhoods.first
    county = owned_neighbourhoods.find { |u| u.unit == 'county' }
    unowned_neighbourhood = create(:neighbourhood)

    assert_not @neighbourhood_region_admin.can_view_neighbourhood_by_id? region.parent.id
    assert_not @neighbourhood_region_admin.can_view_neighbourhood_by_id? unowned_neighbourhood.id

    assert @neighbourhood_region_admin.can_view_neighbourhood_by_id? county.id
  end

  test 'is neighbourhood admin for partner when neighbourhood admin for partners neighbourhood or service area' do
    partner_in_neighbourhood = create(:partner)
    partner_with_service_area_in_neighbourhood = create(:partner)
    partner_outside_neighbourhood = create(:moss_side_partner)

    partner_in_neighbourhood.address.neighbourhood = @neighbourhood_region_admin.neighbourhoods.first
    partner_in_neighbourhood.save!

    partner_with_service_area_in_neighbourhood.service_areas.create(
      neighbourhood: @neighbourhood_region_admin.neighbourhoods.first
    )

    assert @neighbourhood_region_admin.neighbourhood_admin_for_partner?(partner_in_neighbourhood.id)
    assert @neighbourhood_region_admin.neighbourhood_admin_for_partner?(partner_with_service_area_in_neighbourhood.id)
    assert_not @neighbourhood_region_admin.neighbourhood_admin_for_partner?(partner_outside_neighbourhood.id)
  end

  test 'is the only possible neighbourhood admin for a partner when admin for partners neighbourhood or service area and partner has no other neighbourhoods' do
    partner_in_neighbourhood = create(:partner)
    partner_outside_neighbourhood = create(:moss_side_partner)

    partner_in_neighbourhood.address.neighbourhood = @neighbourhood_region_admin.neighbourhoods.first
    partner_in_neighbourhood.save!

    partner_in_neighbourhood.service_areas.create(
      neighbourhood: @neighbourhood_region_admin.neighbourhoods.first
    )

    assert @neighbourhood_region_admin.only_neighbourhood_admin_for_partner?(partner_in_neighbourhood.id)
    assert_not @neighbourhood_region_admin.only_neighbourhood_admin_for_partner?(partner_outside_neighbourhood.id)
  end

  test 'is not the only possible neighbourhood admin for partner when admin for partners neighbourhood or service area and partner has other neighbourhoods' do
    partner_address_outside_neighbourhood = create(:moss_side_partner)
    partner_servicing_outside_neighbourhood = create(:moss_side_partner)

    partner_servicing_outside_neighbourhood.address.neighbourhood = @neighbourhood_region_admin.neighbourhoods.first
    partner_servicing_outside_neighbourhood.save!

    partner_servicing_outside_neighbourhood.service_areas.create(
      neighbourhood: partner_address_outside_neighbourhood.address.neighbourhood
    )

    partner_address_outside_neighbourhood.service_areas.create(
      neighbourhood: @neighbourhood_region_admin.neighbourhoods.first
    )

    assert_not @neighbourhood_region_admin.only_neighbourhood_admin_for_partner?(partner_address_outside_neighbourhood.id)
    assert_not @neighbourhood_region_admin.only_neighbourhood_admin_for_partner?(partner_servicing_outside_neighbourhood.id)
  end

  test 'can edit partners' do
    user = create(:user)
    partner = create(:partner)
    user.partners << partner

    assert user.admin_for_partner?(partner.id)
  end

  test 'updates user role on save' do
    # Does this person manage at least one partner?
    @user.partners << create(:partner)
    @user.save
    assert_predicate @user, :partner_admin?

    # Does this person manage at least one tag?
    @user.tags << create(:tag)
    @user.save
    assert_predicate @user, :tag_admin?

    # Is this person a root? If they are, they're also a secretary
    @user.update(role: :root)
    assert_predicate @user, :root?
  end

  test 'full name method gives sensible responses' do
    @user.update(first_name: '', last_name: '')
    assert_equal '', @user.full_name
    @user.update(first_name: 'Joan', last_name: '')
    assert_equal 'Joan', @user.full_name
    @user.update(first_name: '', last_name: 'Jones')
    assert_equal 'Jones', @user.full_name
    @user.update(first_name: 'Joan', last_name: 'Jones')
    assert_equal 'Joan Jones', @user.full_name
  end

  test 'admin name method gives sensible responses' do
    @user.update(first_name: 'Joan', last_name: '')
    assert_equal "Joan <#{@user.email}>", @user.admin_name
    @user.update(first_name: '', last_name: 'Jones')
    assert_equal "JONES <#{@user.email}>", @user.admin_name
    @user.update(first_name: 'Joan', last_name: 'Jones')
    assert_equal "JONES, Joan <#{@user.email}>", @user.admin_name
  end

  test 'without skip_password_validation' do
    user = User.new(email: 'test@test.com', role: 'citizen')
    assert_not_predicate user, :valid?
  end

  test 'with skip_password_valiation' do
    user = User.new(email: 'test@test.com', role: 'citizen')
    user.skip_password_validation = true
    assert_predicate user, :valid?
  end

  test 'Partnership tag can be assigned to User' do
    @user.tags << Partnership.first
    @user.save!
    assert_equal(1, @user.tags.length)
  end

  test 'Category tag cannot be assigned to User' do
    error_message = 'Can only be of type Partnership'
    @user.tags << Category.first
    assert_not @user.valid? # runs validations in the background
    assert_equal [error_message], @user.errors[:tags]
  end

  test 'Faciltiy tag cannot be assigned to User' do
    error_message = 'Can only be of type Partnership'
    @user.tags << Facility.first
    assert_not @user.valid? # runs validations in the background
    assert_equal [error_message], @user.errors[:tags]
  end
end
