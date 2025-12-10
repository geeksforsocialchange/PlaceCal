# frozen_string_literal: true

require 'test_helper'

class PartnerServiceAreaTest < ActiveSupport::TestCase
  setup do
    @neighbourhood = neighbourhoods(:one)
    @user = create(:user)
    @user.neighbourhoods << @neighbourhood
    @partner = build(:partner, address: nil, accessed_by_user: @user)
  end

  test 'is valid when empty' do
    # give partner an address the user administrates
    @partner.address = create(:address, neighbourhood: @neighbourhood)
    @partner.save!

    assert_predicate @partner, :valid?, 'Partner (without service_area) is not valid'
  end

  test 'is valid when set, can be accessed' do
    model = build(:ashton_service_area_partner)
    model.save!
    assert_predicate model, :valid?

    service_areas = model.service_areas
    assert_equal 1, service_areas.count
  end

  test 'can be assigned' do
    @partner.accessed_by_user = @user
    @partner.service_area_neighbourhoods << @neighbourhood
    @partner.save!

    assert_predicate @partner, :valid?, 'Partner (with service_area) is not valid'

    neighbourhood_count = @partner.service_area_neighbourhoods.count
    assert_equal 1, neighbourhood_count, 'count neighbourhoods'
  end

  test 'must be unique' do
    @partner.address = create(:address, neighbourhood: @neighbourhood)
    @partner.save!

    assert_raises ActiveRecord::RecordInvalid do
      @partner.service_areas.create!(neighbourhood: @neighbourhood)
      @partner.service_areas.create!(neighbourhood: @neighbourhood)
    end
    # need to also test this with regards to model creation from the web front-end
  end

  test 'can be read when present' do
    @partner.address = create(:address, neighbourhood: @neighbourhood)
    @partner.save!

    other_neighbourhood = create(:ashton_neighbourhood)
    @partner.service_areas.create! neighbourhood: @neighbourhood
    @partner.service_areas.create! neighbourhood: other_neighbourhood

    neighbourhoods = @partner.service_area_neighbourhoods.order('neighbourhoods.name').all
    assert_equal(2, neighbourhoods.count, 'Failed to count neighbourhoods')

    n1 = neighbourhoods[0]
    assert_equal 'Ashton Hurst', n1.name

    n2 = neighbourhoods[1]
    assert_equal 'Hulme', n2.name
  end

  test 'must be within users neighbourhoods' do
    @partner.service_areas.build neighbourhood: create(:moss_side_neighbourhood)
    @partner.validate

    assert_not_predicate(@partner, :valid?, 'Partner should not be valid')
  end

  test 'can be set by root users' do
    root_user = create(:root)
    other_neighbourhood = create(:moss_side_neighbourhood)

    @partner.accessed_by_user = root_user
    @partner.service_area_neighbourhoods << other_neighbourhood
    @partner.save!

    assert_predicate @partner, :valid?, 'Partner (with service_area) should be valid'

    neighbourhood_count = @partner.service_area_neighbourhoods.count
    assert_equal 1, neighbourhood_count, 'count neighbourhoods'
  end
end
