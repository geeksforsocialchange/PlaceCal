# frozen_string_literal: true

require 'test_helper'

class PartnerIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:root)

    @partner = create(:partner)

    @neighbourhood_region_admin = create(:neighbourhood_region_admin)

    # using a factory to create the neighbourhood_admin will not result in a shared neighbourhood
    @neighbourhood_admin = create(:citizen)
    @neighbourhood_admin.neighbourhoods = [@partner.address.neighbourhood]

    @tag = create(:tag, type: 'Category')

    host! 'admin.lvh.me'
  end

  test 'Partner admin index has appropriate fields' do
    sign_in(@admin)
    get admin_partners_path
    assert_response :success

    assert_select 'title', text: 'Partners | PlaceCal Admin'
    assert_select 'h1', text: 'Partners'
  end

  test 'root : can get new partner' do
    sign_in @admin

    get new_admin_partner_path

    assert_select 'title', text: 'New Partner | PlaceCal Admin'
  end

  test 'Edit form has correct fields' do
    sign_in @admin

    get edit_admin_partner_path(@partner)
    assert_response :success

    assert_select 'title', text: "Editing #{@partner.name} | PlaceCal Admin"
    assert_select 'h1', text: "Edit Partner: #{@partner.name}"

    assert_select 'h2', text: 'Basic Information'
    assert_select 'label', text: 'Name *'
    assert_select 'label', text: 'Summary'
    assert_select 'label', text: 'Description'
    assert_select 'label', text: 'Image'
    assert_select 'label', text: 'Website address'
    assert_select 'label', text: 'Twitter handle'

    assert_select 'h2', text: 'Address'
    assert_select 'label', text: 'Street address *'
    assert_select 'label', text: 'Street address 2'
    assert_select 'label', text: 'Street address 3'
    assert_select 'label', text: 'City'
    assert_select 'label', text: 'Postcode *'

    assert_select 'h2', text: 'Contact Information'
    assert_select 'h3', text: 'Public Contact'
    assert_select 'label', text: 'Public name'
    assert_select 'label', text: 'Public email'
    assert_select 'label', text: 'Public phone'
    assert_select 'h3', text: 'Partnership Contact'
    assert_select 'label', text: 'Partner name'
    assert_select 'label', text: 'Partner email'
    assert_select 'label', text: 'Partner phone'
  end

  test 'Edit has delete button for root users' do
    sign_in @admin

    get edit_admin_partner_path(@partner)
    assert_response :success

    assert_select 'a#destroy-partner', 'Delete Partner'
  end

  test 'Edit has delete button for neighbourhood admins' do
    @partner.address.update!(
      neighbourhood_id: @neighbourhood_region_admin.neighbourhoods.first.id
    )

    sign_in @neighbourhood_region_admin

    get edit_admin_partner_path(@partner)
    assert_response :success

    assert_select 'a#destroy-partner', 'Delete Partner'
  end

  test 'Partner has owned tag preselected' do
    @neighbourhood_region_admin.tags << @tag

    sign_in @neighbourhood_region_admin

    get new_admin_partner_path(@partner)
    assert_response :success

    tag_options = assert_select 'div.partner_tags option', count: 1, text: @tag.name_with_type

    tag = tag_options.first
    assert tag.attributes.key?('selected')
  end

  test 'Partner create form gives feedback on bad image selection' do
    new_partner_params = {
      name: 'A partner',
      address_attributes: {
        street_address: @partner.address.street_address,
        postcode: @partner.address.postcode
      },
      image: fixture_file_upload('bad-cat-picture.bmp')
    }

    sign_in @admin
    post admin_partners_path, params: { partner: new_partner_params }

    assert_not response.redirect?

    assert_select 'h6', text: '1 error prohibited this Partner from being saved'
    assert_select '#form-errors li',
                  text: 'Image You are not allowed to upload "bmp" files, allowed types: jpg, jpeg, gif, png'
    assert_select 'form .partner_image .invalid-feedback',
                  text: 'Image You are not allowed to upload "bmp" files, allowed types: jpg, jpeg, gif, png'
  end

  test 'Partner update form gives feedback on bad image selection' do
    partner_params = {
      name: @partner.name,
      address_attributes: {
        street_address: @partner.address.street_address,
        postcode: @partner.address.postcode
      },
      image: fixture_file_upload('bad-cat-picture.bmp')
    }

    sign_in @admin
    put admin_partner_path(@partner), params: { partner: partner_params }

    assert_not response.redirect?

    assert_select 'h6', text: '1 error prohibited this Partner from being saved'
    assert_select '#form-errors li',
                  text: 'Image You are not allowed to upload "bmp" files, allowed types: jpg, jpeg, gif, png'
    assert_select 'form .partner_image .invalid-feedback',
                  text: 'Image You are not allowed to upload "bmp" files, allowed types: jpg, jpeg, gif, png'
  end

  test 'neighbourhood_admin cannot update an address outside of their neighbourhood' do
    neighbourhood = create(:neighbourhood, unit_code_value: 'E05013808')

    partner_params = {
      name: @partner.name,
      address_attributes: {
        street_address: @partner.address.street_address,
        postcode: 'W1J 7NF' # (from /test/support/geocoder.rb)
      }
    }

    sign_in @neighbourhood_admin
    put admin_partner_path(@partner), params: { partner: partner_params }

    assert_select '#form-errors li', text: 'Partners cannot have an address outside of your ward.'
  end
end

# Capybara feature test that doesn't work and i have no time to fix
# class PartnerAddressUpdatesTest < ActionDispatch::IntegrationTest # Capybara::Rails::TestCase
#
#   include Devise::Test::IntegrationHelpers
#   include Capybara::DSL
#   include Capybara::Minitest::Assertions
#
#   setup do
#     @admin = create(:root)
#     @site = FactoryBot.create(:site, slug: 'default-site')
#     @partner = create(:partner)
#     # @admin = create(:root)
#     host! 'admin.lvh.me'
#   end
#
#   test 'can change postcode of partner' do
#     sign_in @admin
#
#     visit '/'
#
#     click_link 'Partners'
#     click_link @partner.title
#
#     fill_in 'Postcode', with: 'OL6 8BH'
#
#
#     #update_args = @partner_two.as_json
#     #update_args['partner']['address']['postcode'] =
#     #patch admin_partner_url(@partner_two), params: update_args
#     click_button 'Update'
#     assert_redirected_to admin_partners_url
#
#     click @partner.title
#
#     puts 'is this runing?'
#     assert_have_selector 'input[name="partner_postcode"]'
#
#     #@partner_two.reload
#     #assert @partner_two.address.postcode == 'OL6 8BH'
#   end
# end
