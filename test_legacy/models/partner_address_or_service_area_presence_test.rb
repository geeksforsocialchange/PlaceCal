# frozen_string_literal: true

require 'test_helper'

class PartnerAddressOrServiceAreaPresenceTest < ActiveSupport::TestCase
  setup do
    @user = create(:neighbourhood_admin)
    @root_user = create(:root)
    @neighbourhood = neighbourhoods(:one)
    @user.neighbourhoods << @neighbourhood

    @new_partner = Partner.new(
      name: 'Alpha name',
      summary: 'Summary of alpha',
      accessed_by_user: @user
    )
    @new_partner_for_root = Partner.new(
      name: 'Alpha name',
      summary: 'Summary of alpha',
      accessed_by_user: @root_user
    )
  end

  ####  neighbourhood admin tests

  test 'with neighbourhood admin user - is invalid if both service area and address not present' do
    @new_partner.validate

    assert_not_predicate(@new_partner, :valid?, 'Partner should be invalid')

    base_errors = @new_partner.errors[:base]
    assert_predicate base_errors.length, :positive?
  end

  test 'with neighbourhood admin user - is invalid if service area set outside neighbourhood and address not present' do
    @new_partner.service_areas.build neighbourhood: create(:neighbourhood)
    @new_partner.validate

    assert_not_predicate(@new_partner, :valid?, 'Partner should be invalid')

    base_errors = @new_partner.errors[:base]
    assert_predicate base_errors.length, :positive?
  end

  test 'with neighbourhood admin user - is invalid if address set outside neighbourhood and service area not present' do
    address = build(:address, neighbourhood: create(:neighbourhood))
    @new_partner.validate

    assert_not_predicate(@new_partner, :valid?, 'Partner should be invalid')

    base_errors = @new_partner.errors[:base]
    assert_predicate base_errors.length, :positive?
  end

  test 'with neighbourhood admin user - is valid with owned service_area set' do
    @new_partner.service_areas.build neighbourhood: @neighbourhood
    @new_partner.validate

    assert_predicate(@new_partner, :valid?, 'Partner should be valid')
  end

  test 'with neighbourhood admin user - is valid with owned address set' do
    address = build(:address, neighbourhood: @neighbourhood)

    @new_partner.address = address
    @new_partner.save!

    assert_predicate(@new_partner, :valid?, 'Partner should be valid')
  end

  ####  root user tests

  test 'with root user - is invalid if both service area and address not present' do
    @new_partner_for_root.validate

    assert_not_predicate(@new_partner_for_root, :valid?, 'Partner should be invalid')

    base_errors = @new_partner_for_root.errors[:base]
    assert_predicate base_errors.length, :positive?
  end

  test 'with root user - is valid with service_area set' do
    @new_partner_for_root.service_areas.build neighbourhood: create(:neighbourhood)
    @new_partner_for_root.validate

    assert_predicate(@new_partner_for_root, :valid?, 'Partner should be valid')
  end

  test 'with root user - is valid with address set' do
    address = build(:address, neighbourhood: create(:neighbourhood))

    @new_partner_for_root.address = address
    @new_partner_for_root.save!

    assert_predicate(@new_partner_for_root, :valid?, 'Partner should be valid')
  end

  test 'with root user - is valid with both service_area and address set' do
    address = build(:address)

    @new_partner_for_root.address = address
    @new_partner_for_root.service_areas.build neighbourhood: create(:neighbourhood)
    @new_partner_for_root.validate

    assert_predicate(@new_partner_for_root, :valid?, 'Partner should valid')
  end
end
