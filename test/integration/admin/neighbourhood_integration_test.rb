# frozen_string_literal: true

require 'test_helper'

class AdminNeighbourhoodIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @root = create(:root)

    @neighbourhood = create(:neighbourhood)

    @neighbourhood_admin = create(:neighbourhood_admin)
    # @neighbourhood_admin = @neighbourhood.users.first

    @neighbourhoods = create_list(:neighbourhood, 4)

    # TODO: Change this 15 to be reflective of the current record limit
    @number_of_neighbourhoods = 15

    @neighbourhoods << @neighbourhood
    get 'http://admin.lvh.me'
  end

  test 'Index shows correct neighbourhoods for root' do
    sign_in(@root)
    get admin_neighbourhoods_path
    # See all neighbourhoods

    assert_select 'title', text: 'Neighbourhoods | PlaceCal Admin'
    assert_select 'tbody tr', count: @number_of_neighbourhoods
  end

  test 'Index shows correct neighbourhoods for neighbourhood admin' do
    sign_in(@neighbourhood_admin)
    get admin_neighbourhoods_path
    # See just the neighbourhood they admin
    assert_select 'tbody tr', count: 1
  end

  test 'Edit form has correct fields for root' do
    sign_in @root
    get edit_admin_neighbourhood_path(@neighbourhood)
    assert_response :success

    assert_select 'label', 'Name'
    assert_select 'label', 'Abbreviated name'
    assert_select 'label', 'Unit'
    assert_select 'label', 'Unit code key'
    assert_select 'label', 'Unit name'
    assert_select 'label', 'Unit code value'
    assert_select 'label', 'Users'

    assert_select 'input', value: 'Save'
    assert_select 'a', 'Destroy'
  end

  test 'Edit form has correct fields for neighbourhood admin' do
    sign_in @neighbourhood_admin
    get edit_admin_neighbourhood_path(@neighbourhood)
    assert_response :success

    assert_select 'label', 'Name'
    assert_select 'label', 'Abbreviated name'
    assert_select 'label', 'Unit'
    assert_select 'label', 'Unit code key'
    assert_select 'label', 'Unit name'
    assert_select 'label', 'Unit code value'
    assert_select 'label', text: 'Users', count: 0

    assert_select 'input', value: 'Save'
    assert_select 'a', text: 'Destroy', count: 0
  end
end
