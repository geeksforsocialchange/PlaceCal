# frozen_string_literal: true

require "test_helper"

class PartnerAddressOrServiceAreaPermissionsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @user_neighbourhood = neighbourhoods(:one)

    @user.neighbourhoods << @user_neighbourhood

    @new_partner = build(:partner, address: nil, accessed_by_user: @user)
  end

  test "valid if address is in user ward" do
    @new_partner.address = create(:address, neighbourhood: @user_neighbourhood)
    @new_partner.save!

    assert @new_partner.valid?
  end

  test "verify: with service area in user neighbourhoods" do
    @new_partner.service_area_neighbourhoods << @user_neighbourhood
    @new_partner.save!

    assert @new_partner.valid?
  end

  test "verify: with service area contained within users neighbourhood subtrees" do
    child_neighbourhood = create(:neighbourhood)
    parent_neighbourhood = child_neighbourhood.parent

    @user.neighbourhoods << parent_neighbourhood

    @new_partner.service_area_neighbourhoods << child_neighbourhood
    @new_partner.save!

    assert @new_partner.valid?
  end

  test "with a service area not in user's ward set" do
    other_neighbourhood = neighbourhoods(:two)

    @new_partner.service_area_neighbourhoods << @user_neighbourhood
    @new_partner.service_area_neighbourhoods << other_neighbourhood

    assert @new_partner.valid? == false,
           "Users cannot create service areas outside of their neighbourhoods"
  end
end
