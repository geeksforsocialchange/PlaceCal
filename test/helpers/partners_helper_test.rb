# frozen_string_literal: true

require 'test_helper'

class PartnersHelperTest < ActionView::TestCase
  setup do
    @root = create(:root)
    @partner = create(:partner)
    @hoods = [
      create(:neighbourhood, name: 'alpha'),
      create(:neighbourhood, name: 'beta'),
      create(:neighbourhood, name: 'cappa')
    ]

    @partnership_admin = create(:neighbourhood_admin)

    @partner_in_neighbourhood = create(:partner)
    @partner_in_neighbourhood.address.neighbourhood = @partnership_admin.neighbourhoods.first
    @partner_in_neighbourhood.save!

    @partner_servicing_neighbourhood = create(:partner)
    @partner_servicing_neighbourhood.service_area_neighbourhoods << @partnership_admin.neighbourhoods.first
    @partner_servicing_neighbourhood.save!

    @partnership_tag = create(:partnership)
    @other_partnership_tag = create(:partnership)
    @other_partnership_tag_belonging_to_partner = create(:partnership)
    @category_tag = create(:category)
    @system_tag = create(:system_tag)
    @facility_tag = create(:tag)

    @partnership_admin.tags << @partnership_tag
    @partner_in_neighbourhood.tags << @other_partnership_tag_belonging_to_partner
  end

  # testing partner_service_area_text

  test 'shows only one text correctly' do
    @partner.service_areas.create neighbourhood: @hoods[0]

    output = partner_service_area_text(@partner)

    assert_equal('alpha', output)
  end

  test 'shows two texts correctly' do
    @partner.service_areas.create neighbourhood: @hoods[0]
    @partner.service_areas.create neighbourhood: @hoods[1]

    output = partner_service_area_text(@partner)

    assert_equal('alpha and beta', output)
  end

  test 'shows N texts correctly' do
    @partner.service_areas.create neighbourhood: @hoods[0]
    @partner.service_areas.create neighbourhood: @hoods[1]
    @partner.service_areas.create neighbourhood: @hoods[2]

    output = partner_service_area_text(@partner)

    assert_equal('alpha, beta and cappa', output)
  end

  test 'root user - options_for_partner_partnerships with no partner returns all allowed partners' do
    def policy_scope(_scope)
      Pundit.policy_scope!(@root, Partnership)
    end

    expected = Partnership.order(:name).select(:name, :type, :id).map { |r| [r.name, r.id] }

    assert_equal(expected, options_for_partner_partnerships)
  end

  test 'root user - options_for_partner_partnerships with partner returns all allowed partners' do
    def policy_scope(_scope)
      Pundit.policy_scope!(@root, Partnership)
    end

    expected = Partnership.order(:name).select(:name, :type, :id).map { |r| [r.name, r.id] }

    assert_equal(expected, options_for_partner_partnerships)
  end

  test 'partnership admin user - options_for_partner_partnerships with no partner returns neighbourhood partners' do
    def policy_scope(_scope)
      Pundit.policy_scope!(@partnership_admin, Partnership)
    end

    expected = [@partnership_tag].map { |r| [r.name, r.id] }

    assert_equal(expected.sort, options_for_partner_partnerships.sort)
  end

  test 'partnership admin user - options_for_partner_partnerships with partner returns neighbourhood partners' do
    def policy_scope(_scope)
      Pundit.policy_scope!(@partnership_admin, Partnership)
    end

    expected = [@partnership_tag].map { |r| [r.name, r.id] }

    assert_equal(expected.sort, options_for_partner_partnerships.sort)
  end
end
