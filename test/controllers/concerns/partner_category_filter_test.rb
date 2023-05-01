
require 'test_helper'

class PartnerCategoryFilterTest < ActionDispatch::IntegrationTest
  setup do
    @category = create(:category)
    @categories = create_list(:category, 4)
    @categories << @category
  end

  test '#is_active?' do
    # is false by default
    filter = PartnerCategoryFilter.new({})
    assert filter.is_active? == false, 'is_active? should be false with no input'
    filter = PartnerCategoryFilter.new(category: @category.id)
    assert filter.is_active?, 'should be active'
  end

  test '#categories' do
    # doesn't find categories that lack partners
    filter = PartnerCategoryFilter.new({})
    found = filter.categories
    assert found.length == 0

    # does find categories assigned to partners
    given_some_partnered_categories_exist
    
    filter = PartnerCategoryFilter.new({})
    found = filter.categories
    assert found.length == 5
  end

  test '#apply_to' do
    Partner.destroy_all
    
    partner_1 = create(:partner)
    partner_2 = create(:partner)
    partner_3 = create(:partner)
    partner_4 = create(:partner)
    
    # returns every partner if no filter category set
    filter = PartnerCategoryFilter.new({})
    query = filter.apply_to(Partner)
    assert query.count == 4

    # returns only partners assigned category (in include mode)
    partner_1.tags << @category
    
    filter = PartnerCategoryFilter.new(category: @category.id)
    query = filter.apply_to(Partner)
    assert query.count == 1

    # returns only partners NOT assigned category (in exclude mode)
    filter = PartnerCategoryFilter.new(category: @category.id, mode: 'exclude')
    query = filter.apply_to(Partner)
    assert query.count == 3
  end

  test '#show_filter?' do
    # is false if no partnered categories found
    filter = PartnerCategoryFilter.new({})
    assert filter.show_filter? == false
    
    # is true when partnered categories found
    given_some_partnered_categories_exist
    
    filter = PartnerCategoryFilter.new({})
    assert filter.show_filter?
  end

  test '#current_category?' do
    # is false when no current category set
    filter = PartnerCategoryFilter.new({})
    assert filter.current_category?(@category) == false

    # is true when current category matches incoming category
    filter = PartnerCategoryFilter.new(category: @category.id)
    assert filter.current_category?(@category) == true
  end

  test 'modes' do
    # default to include mode
    filter = PartnerCategoryFilter.new({})
    assert filter.include_mode?
    assert_not filter.exclude_mode?
    
    # is include mode when set
    filter = PartnerCategoryFilter.new(mode: 'include')
    assert filter.include_mode?
    assert_not filter.exclude_mode?
    
    # is exclude mode when set
    filter = PartnerCategoryFilter.new(mode: 'exclude')
    assert filter.exclude_mode?
    assert_not filter.include_mode?
  end

  # helpers
  def given_some_partnered_categories_exist
    partner = create(:partner)
    
    @categories.each do |category|
      partner.tags << category      
    end
  end
end

