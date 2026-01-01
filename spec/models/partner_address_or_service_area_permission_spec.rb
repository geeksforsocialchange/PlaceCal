# frozen_string_literal: true

require "rails_helper"

RSpec.describe Partner, "address or service area permission validation" do
  let(:user_neighbourhood) { create(:riverside_ward) }
  let(:user) do
    u = create(:user)
    u.neighbourhoods << user_neighbourhood
    u
  end
  let(:new_partner) { build(:partner, address: nil, accessed_by_user: user) }

  it "is valid if address is in user ward" do
    new_partner.address = create(:address, neighbourhood: user_neighbourhood)
    new_partner.save!

    expect(new_partner).to be_valid
  end

  it "is valid with service area in user neighbourhoods" do
    new_partner.service_area_neighbourhoods << user_neighbourhood
    new_partner.save!

    expect(new_partner).to be_valid
  end

  it "is valid with service area contained within users neighbourhood subtrees" do
    # Use a ward which has a parent (district) - base :neighbourhood has no parent
    child_neighbourhood = create(:riverside_ward)
    parent_neighbourhood = child_neighbourhood.parent # millbrook_district

    user.neighbourhoods << parent_neighbourhood

    new_partner.service_area_neighbourhoods << child_neighbourhood
    new_partner.save!

    expect(new_partner).to be_valid
  end

  it "is invalid with a service area not in user's ward set" do
    other_neighbourhood = create(:oldtown_ward)

    new_partner.service_area_neighbourhoods << user_neighbourhood
    new_partner.service_area_neighbourhoods << other_neighbourhood

    expect(new_partner).not_to be_valid
  end
end
