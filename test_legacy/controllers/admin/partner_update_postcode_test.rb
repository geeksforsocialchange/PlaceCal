# frozen_string_literal: true

require 'test_helper'

class PartnerUpdatePostcodeTest < ActionDispatch::IntegrationTest
  setup do
    Neighbourhood.destroy_all

    @neighbourhood_admin = create(:user)
  end

  test 'can change postcode of partner' do
    neighbourhood_1 = Neighbourhood.create!( # 'M15 5DD'
      name: 'Neighbourhood 1',
      name_abbr: '',
      unit: 'ward',
      unit_code_key: 'WD19CD',
      unit_code_value: 'E05011368',
      unit_name: 'Hulme',
      release_date: DateTime.new(2023, 7)
    )

    neighbourhood_2 = Neighbourhood.create!( # 'OL6 8BH'
      name: 'Neighbourhood 2',
      name_abbr: '',
      unit: 'ward',
      unit_code_key: 'WD19CD',
      unit_code_value: 'E05000800',
      unit_name: 'Ashton Hurst',
      release_date: DateTime.new(2023, 7)
    )

    @neighbourhood_admin.neighbourhoods << neighbourhood_1
    @neighbourhood_admin.neighbourhoods << neighbourhood_2

    @partner = Partner.new(name: 'A new partner')
    @partner.address = Address.create!(
      street_address: '123 Street',
      country_code: 'UK',
      postcode: 'M15 5DD'
    )
    @partner.save!

    sign_in @neighbourhood_admin

    update_args = {
      partner: {
        name: @partner.name,
        address_attributes: {
          street_address: @partner.address.street_address,
          postcode: 'OL6 8BH'
        }
      }
    }

    patch admin_partner_url(@partner), params: update_args
    assert_redirected_to edit_admin_partner_url(@partner)

    @partner.reload
    assert_equal('OL6 8BH', @partner.address.postcode)
  end
end
