# frozen_string_literal: true

require 'test_helper'

class Admin::PartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @citizen = create(:user)

    @address = create(:address)
    @neighbourhood_admin_neighbourhood = @address.neighbourhood
    @partner_neighbourhood = create(:moss_side_neighbourhood)
    @other_neighbourhood_admin_neighbourhood = create(:ashton_neighbourhood)

    @neighbourhood_admin = create(:user)
    @neighbourhood_admin.neighbourhoods << @neighbourhood_admin_neighbourhood
    @neighbourhood_admin.neighbourhoods << @other_neighbourhood_admin_neighbourhood

    @partner = create(:partner, address_id: @address.id)
    @partner.service_areas.build(neighbourhood: @partner_neighbourhood)
    @partner.save!

    @partner_admin = create(:user)
    @partner_admin.partners << @partner

    @partner_two = create(:partner)

    host! 'admin.lvh.me'
  end

  # Partner Index
  #
  #   Show every Partner for roots
  #   Show an empty page for citizens
  #   TODO: test for more permutations

  it_allows_access_to_index_for(%i[root]) do
    get admin_partners_url
    assert_response :success
    # Has a button allowing us to add new Partners
    assert_select 'a', 'Add New Partner'
    # Returns one entry in the table
    assert_select 'tbody tr', 2
  end

  it_allows_access_to_index_for(%i[partner_admin]) do
    get admin_partners_url
    assert_response :success
    assert_select 'td', @partner.name
    assert_select 'tbody tr', 1
    # Nothing to show in the table
  end

  it_allows_access_to_index_for(%i[neighbourhood_admin]) do
    get admin_partners_url
    assert_response :success
    # assert_select 'a', 'Edit'
    assert_select 'tbody tr', 2
    # Nothing to show in the table
  end

  it_denies_access_to_index_for(%i[citizen]) do
    get admin_partners_url
    assert_response :success
    # Nothing to show in the table
    assert_select 'tbody tr', 0
  end

  # Show partner
  #
  #   This shouldn't really happen normally.
  #   Redirect to edit page.
  it_allows_access_to_show_for(%i[root neighbourhood_admin partner_admin]) do
    get admin_partner_url(@partner)
    assert_redirected_to edit_admin_partner_url(@partner)
  end

  # New & Create Partner
  #
  #   Allow secretaries to create new Partners
  #   Everyone else, redirect to admin_partners_url

  it_allows_access_to_new_for(%i[root neighbourhood_admin]) do
    get new_admin_partner_url
    assert_response :success
  end

  it_denies_access_to_new_for(%i[partner_admin]) do
    get new_admin_partner_url
    assert_redirected_to admin_partners_url
  end

  it_allows_access_to_create_for(%i[root neighbourhood_admin]) do
    assert_difference('Partner.count') do
      post admin_partners_url,
           params: { partner: { name: 'A new partner',
                                address_attributes: {
                                  street_address: '123 Moss Ln E',
                                  postcode: 'M15 5DD'
                                } } }
    end
  end

  it_denies_access_to_create_for(%i[partner_admin]) do
    assert_difference('Partner.count', 0) do
      post admin_partners_url,
           params: { partner: { name: 'A new partner' } }
    end
  end

  # Edit & Update Partner
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_partners_url

  it_allows_access_to_edit_for(%i[root neighbourhood_admin partner_admin]) do
    get edit_admin_partner_url(@partner)
    assert_response :success
  end

  it_denies_access_to_edit_for(%i[partner_admin]) do
    get edit_admin_partner_url(@partner_two)
    assert_redirected_to admin_partners_url
  end

  it_allows_access_to_update_for(%i[root neighbourhood_admin partner_admin]) do
    patch admin_partner_url(@partner),
          params: { partner: { name: 'Updated partner name' } }
    # Redirect to main partner screen
    assert_redirected_to edit_admin_partner_url(@partner)
  end

  # For partner not assigned or in area
  it_denies_access_to_update_for(%i[partner_admin]) do
    patch admin_partner_url(@partner_two),
          params: { partner: { name: 'Updated partner name' } }
    assert_redirected_to admin_partners_url
  end

  test 'it allows access to update for wardless user' do
    partner = create(:partner)
    user = create(:citizen, partners: [partner])
    access_info = 'This is some accessibility info'

    sign_in user

    patch admin_partner_url(partner),
          params: { partner: { accessibility_info: access_info } }

    assert_redirected_to edit_admin_partner_url(partner)
    assert_equal Partner.find_by(id: partner.id).accessibility_info, access_info
  end

  # Delete Partner
  #
  #   Allow roots to delete all Partners
  #   Everyone else redirect to admin_partners_url

  it_allows_access_to_destroy_for(%i[root partner_admin]) do
    assert_difference('Partner.count', -1) do
      delete admin_partner_url(@partner)
    end

    assert_redirected_to admin_partners_url
  end

  # neighbourhood admins can only destroy if partner is only in their neighbourhoods
  it_allows_access_to_destroy_for(%i[neighbourhood_admin]) do
    @partner.service_areas = []
    assert_difference('Partner.count', -1) do
      delete admin_partner_url(@partner)
    end

    assert_redirected_to admin_partners_url
  end

  # neighbourhood admins can only destroy if partner is only in their neighbourhoods
  it_denies_access_to_destroy_for(%i[citizen neighbourhood_admin]) do
    assert_difference('Partner.count', 0) do
      delete admin_partner_url(@partner)
    end
  end

  # Setup Partner

  test 'neighbourhood_admin : can access setup' do
    sign_in @neighbourhood_admin

    get setup_admin_partners_url
    assert_response :success
  end

  test 'neighbourhood_admin : can setup new partner in ward' do
    sign_in @neighbourhood_admin

    params = {
      partner: {
        name: 'New Partner',
        address_attributes: {
          street_address: '123 Moss Ln E',
          postcode: 'M15 5DD'
        }
      }
    }

    post setup_admin_partners_url, params: params
    assert_redirected_to new_admin_partner_url(params)
  end

  test 'neighbourhood_admin : cannot setup new partner not in ward' do
    sign_in @neighbourhood_admin

    params = {
      partner: {
        name: 'New Partner',
        address_attributes: {
          street_address: 'Ashton-under-Lyne',
          postcode: 'OL6 8BH'
        }
      }
    }

    post setup_admin_partners_url, params: params

    assert_template :setup
  end

  test 'neighbourhood_admin : can see all of a partners service areas' do
    sign_in @neighbourhood_admin
    get edit_admin_partner_url(@partner)
    all_neighbourhoods = [
      @partner_neighbourhood,
      @neighbourhood_admin_neighbourhood,
      @other_neighbourhood_admin_neighbourhood
    ]

    assert_equal all_neighbourhoods.sort, @controller.view_assigns['all_neighbourhoods'].sort
  end

  test 'neighbourhood_admin: cannot remove service area from partner with no address' do
    sign_in @neighbourhood_admin

    partner_with_no_address = create(:bare_partner, name: 'test partner')
    partner_with_no_address.service_areas.create(
      neighbourhood: @neighbourhood_admin_neighbourhood
    )
    partner_with_no_address.address = nil
    partner_with_no_address.save!

    edit_params = {
      partner: {
        service_areas_attributes: {
          '0':
          {
            id: partner_with_no_address.service_areas[0].id,
            neighbourhood_id: @neighbourhood_admin_neighbourhood.id,
            _destroy: '1'
          }
        }
      }
    }

    patch admin_partner_url(partner_with_no_address), params: edit_params

    assert_response :redirect
    assert_equal 'Partners must have an address or a service area inside your neighbourhood', flash[:danger]
  end

  test 'root user clear address on partner clears address' do
    sign_in @root

    delete clear_address_admin_partner_path(@partner)
    assert_response :success

    @partner.reload
    assert_nil @partner.address

    # will not work if no address is set
    delete clear_address_admin_partner_path(@partner)
    assert_response :unprocessable_entity
  end

  test 'partner name availability endpoint' do
    sign_in @root

    # yes
    get lookup_name_admin_partners_path(name: 'alpha-beta')
    payload = response.parsed_body
    assert payload['name_available']
    # puts response.body

    # no
    partner = create(:partner)
    get lookup_name_admin_partners_path(name: 'alpha-beta')
    payload = response.parsed_body
    assert payload['name_available']
  end
end
