# frozen_string_literal: true

require 'test_helper'

class Admin::PartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @root = create(:root)
    @neighbourhood_admin = create(:neighbourhood_admin)
    @citizen = create(:user)

    @neighbourhood_admin = create(:neighbourhood_admin)
    @neighbourhood = @neighbourhood_admin.neighbourhoods.first

    @partner_admin = create(:partner_admin)
    @partner = @partner_admin.partners.first

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
    assert_select 'tbody tr', 1
  end

  it_allows_access_to_index_for(%i[partner_admin]) do
    get admin_partners_url
    assert_response :success
    assert_select 'a', 'Edit'
    assert_select 'tbody tr', 1
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
  it_allows_access_to_show_for(%i[neighbourhood_admin partner_admin]) do
    get admin_partner_url(@partner)
    assert_redirected_to edit_admin_partner_url(@partner)
  end

  # New & Create Partner
  #
  #   Allow secretaries to create new Partners
  #   Everyone else, redirect to admin_partners_url

  it_allows_access_to_new_for(%i[neighbourhood_admin]) do
    get new_admin_partner_url
    assert_response :success
  end

  it_allows_access_to_create_for(%i[neighbourhood_admin]) do
    assert_difference('Partner.count') do
      post admin_partners_url,
           params: { partner: { name: 'A new partner' } }
    end
  end

  # Edit & Update Partner
  #
  #   Allow roots to edit all places
  #   Everyone else, redirect to admin_partners_url

  it_allows_access_to_edit_for(%i[neighbourhood_admin partner_admin]) do
    get edit_admin_partner_url(@partner)
    assert_response :success
  end

  it_allows_access_to_update_for(%i[neighbourhood_admin partner_admin]) do
    patch admin_partner_url(@partner),
          params: { partner: { name: 'Updated partner name' } }
    # Redirect to main partner screen
    assert_redirected_to edit_admin_partner_url(@partner)
  end

  # Delete Partner
  #
  #   Allow roots to delete all Partners
  #   Everyone else redirect to admin_partners_url

  it_allows_access_to_destroy_for(%i[neighbourhood_admin]) do
    assert_difference('Partner.count', -1) do
      delete admin_partner_url(@partner)
    end

    assert_redirected_to admin_partners_url
  end

  it_denies_access_to_destroy_for(%i[partner_admin citizen]) do
    assert_difference('Partner.count', 0) do
      delete admin_partner_url(@partner)
    end
  end
end
