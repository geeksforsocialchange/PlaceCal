# frozen_string_literal: true

require 'test_helper'

class AdminNeighbourhoodIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @root = create(:root)

    @neighbourhood = create(:neighbourhood)
    @neighbourhood_admin = @neighbourhood.users.first
    @neighbourhoods = create_list(:neighbourhood, 4)
    @number_of_neighbourhoods = Neighbourhood.where(unit: 'ward').length
    @neighbourhoods << @neighbourhood
    get "http://admin.lvh.me"
  end

  test "Index shows correct neighbourhoods for root" do
    sign_in(@root)
    get admin_neighbourhoods_path
    # See all neighbourhoods
    assert_select 'tbody tr', count: @number_of_neighbourhoods
  end

  test "Index shows correct neighbourhoods for neighbourhood admin" do
    sign_in(@neighbourhood_admin)
    get admin_neighbourhoods_path
    # See just the neighbourhood they admin
    assert_select 'tbody tr', count: 1
  end

  test "Edit form has correct fields for root" do
    sign_in @root
    get edit_admin_neighbourhood_path(@neighbourhood)
    assert_response :success

    assert_select 'label', 'Name'
    assert_select 'label', 'Abbreviated name'
    assert_select 'label', 'District'
    assert_select 'label', 'County'
    assert_select 'label', 'Region'
    assert_select 'label', 'WD19CD'
    assert_select 'label', 'WD19NM'
    assert_select 'label', 'Users'

    assert_select 'h2', 'Overwrite with ward info'

    assert_select 'input', value: 'Save'
    assert_select 'a', 'Destroy'
  end

  test "Edit form has correct fields for neighbourhood admin" do
    sign_in @neighbourhood_admin
    get edit_admin_neighbourhood_path(@neighbourhood)
    assert_response :success

    assert_select 'label', 'Name'
    assert_select 'label', 'Abbreviated name'
    assert_select 'label', 'District'
    assert_select 'label', 'County'
    assert_select 'label', 'Region'
    assert_select 'label', 'WD19CD'
    assert_select 'label', 'WD19NM'
    assert_select 'label', text: 'Users', count: 0

    assert_select 'h2', text: 'Overwrite with ward info', count: 0

    assert_select 'input', value: 'Save'
    assert_select 'a', text: 'Destroy', count: 0
  end
end
