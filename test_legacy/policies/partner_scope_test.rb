# frozen_string_literal: true

require 'test_helper'

class PartnerScopeTest < ActiveSupport::TestCase
  setup do
    @normal_user = create(:citizen)
    @basic_partner = create(:partner)
  end

  test 'returns nothing' do
    assert_empty(permitted_records(@normal_user, Partner))
  end

  test 'scope on ownership' do # test_scope_for_ownership
    # user doesn't own this
    other_neighbourhood = neighbourhoods(:two)
    not_user_address = create(:address, neighbourhood: other_neighbourhood)

    # set up some partners that are not in the users neighbourhoods
    owned_partner_2 = create(:partner, address: not_user_address)
    owned_partner_3 = create(:partner, address: not_user_address)

    # let the user own these partners
    @basic_partner.users  << @normal_user
    owned_partner_2.users << @normal_user
    owned_partner_3.users << @normal_user

    # now we should see all the partners the user owns
    found_partners = permitted_records(@normal_user, Partner)
    assert_equal(3, found_partners.count)
  end

  test 'scope on address' do # test_scope_for_address
    # give the user a neighbourhood to admin
    neighbourhood = neighbourhoods(:one)
    @normal_user.neighbourhoods << neighbourhood

    # create some partners with the users' address
    @basic_partner.address.neighbourhood = neighbourhood

    user_address = create(:address, neighbourhood: neighbourhood)
    partner_2 = create(:partner, address: user_address)
    partner_3 = create(:partner, address: user_address)
    partner_4 = create(:partner, address: user_address)

    # now we should get all the partners in this users neighbourhoods
    found_partners = permitted_records(@normal_user, Partner)
    assert_equal(4, found_partners.count)
  end

  test 'scope on service areas' do # test_scope_for_service_areas
    # give the user a neighbourhood to admin
    neighbourhood = neighbourhoods(:one)
    @normal_user.neighbourhoods << neighbourhood

    # create some service areas
    @basic_partner.service_areas.create neighbourhood: neighbourhood

    4.times do
      partner = build(:partner, address: nil)
      partner.service_areas.build neighbourhood: neighbourhood
      partner.save!
    end

    # we should be able to see all the partners with service areas
    # in the users' neighbourhoods
    found_partners = permitted_records(@normal_user, Partner)
    assert_equal(5, found_partners.count)
  end
end
