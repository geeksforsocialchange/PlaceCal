# frozen_string_literal: true

require 'test_helper'

class AdminNeighbourhoodIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @neighbourhood = create(:neighbourhood)
  end

  test "Edit form has correct fields" do
    get edit_neighbourhood_admin_path(@neighbourhood)

    assert_select 'label', 'Name'
    assert_select 'label', 'Abbreviated name'
    assert_select 'label', 'Ward'
    assert_select 'label', 'District'
    assert_select 'label', 'County'
    assert_select 'label', 'Region'
    assert_select 'label', 'WD19CD'
    assert_select 'label', 'WD19NM'
    assert_select 'label', 'LAD19CD'
    assert_select 'label', 'LAD19NM'
    assert_select 'label', 'CTY19CD'
    assert_select 'label', 'CTY19NM'
    assert_select 'label', 'RGN19CD'
    assert_select 'label', 'RGN19NM'
  end
end
