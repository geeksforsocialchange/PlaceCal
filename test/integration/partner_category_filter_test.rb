# frozen_string_literal: true

require 'test_helper'

class PartnerCategoryFilterTest < ActionDispatch::IntegrationTest
  setup do
    Neighbourhood.destroy_all
    
    @neighbourhood = create(:neighbourhood, unit_code_value: 'E05011368')
    
    @site = create(:site)
    @site.neighbourhoods << @neighbourhood

    @address = create(:address, neighbourhood: @neighbourhood, postcode: 'M15 5DD')

    3.times do |n|
      partner = create(:partner, address: @address, name: "Partner without tag #{n}")
    end
  end

  test 'is hidden when no categories exist' do
    get from_site_slug(@site, partners_path)    
    assert_response :success
    
    assert_select 'button', text: 'Filter', count: 0
    assert_select 'ul#partners li', count: 3
  end

  # include mode
  test 'can be selected to filter only selected category' do
    given_some_tagged_partners_exist
        
    get from_site_slug(@site, partners_path(category: @tag.id))
    
    assert_select 'button', text: 'Filter', count: 1
    assert_select 'ul#partners li', count: 7
  end

  # exclude mode
  test 'can be selected to filter out selected category' do
    given_some_tagged_partners_exist
    
    get from_site_slug(@site, partners_path(category: @tag.id, mode: 'exclude'))
    
    assert_select 'button', text: 'Filter', count: 1
    assert_select 'ul#partners li', count: 3
  end

  def given_some_tagged_partners_exist
    @tag = create(:category)

    7.times do |n|
      partner = create(:partner, address: @address, name: "Partner with tag #{n}")
      partner.tags << @tag
    end
  end
end
