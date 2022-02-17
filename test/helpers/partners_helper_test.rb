# frozen_string_literal: true

require 'test_helper'

class PartnersHelperTest < ActionView::TestCase
  setup do
    @partner = FactoryBot.create(:partner)
    @hoods = [
      FactoryBot.create(:neighbourhood, name: 'alpha'),
      FactoryBot.create(:neighbourhood, name: 'beta'),
      FactoryBot.create(:neighbourhood, name: 'cappa')
    ]
  end

  # testing partner_service_area_text

  test "shows only one text correctly" do
    @partner.service_areas.create neighbourhood: @hoods[0]

    output = partner_service_area_text(@partner)

    assert output == 'alpha'
  end

  test "shows two texts correctly" do
    @partner.service_areas.create neighbourhood: @hoods[0]
    @partner.service_areas.create neighbourhood: @hoods[1]

    output = partner_service_area_text(@partner)

    assert output == 'alpha and beta'
  end

  test "shows N texts correctly" do
    @partner.service_areas.create neighbourhood: @hoods[0]
    @partner.service_areas.create neighbourhood: @hoods[1]
    @partner.service_areas.create neighbourhood: @hoods[2]

    output = partner_service_area_text(@partner)

    assert output == 'alpha, beta and cappa'
  end
end
