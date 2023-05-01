# frozen_string_literal: true

require 'test_helper'

class PartnerCategoryFilterTest < ActionDispatch::IntegrationTest
  setup do
    @category = create(:category)
    @categories = create_list(:category, 4)
    @categories << @category
  end

  test '#active?' do
    # is false by default
    filter = PartnerCategoryFilter.new({})
    assert_not_predicate(filter, :active?, 'is_active? should be false with no input')
    filter = PartnerCategoryFilter.new(category: @category.id)
    assert_predicate filter, :active?, 'should be active'
  end

  test '#categories' do
    # doesn't find categories that lack partners
    filter = PartnerCategoryFilter.new({})
    found = filter.categories
    assert_predicate found.length, :zero?

    # does find categories assigned to partners
    given_some_partnered_categories_exist

    filter = PartnerCategoryFilter.new({})
    found = filter.categories
    assert_equal(5, found.length)
  end

  test '#apply_to' do
    Partner.destroy_all

    partner1 = create(:partner)
    partner2 = create(:partner)
    partner3 = create(:partner)
    partner4 = create(:partner)

    # returns every partner if no filter category set
    filter = PartnerCategoryFilter.new({})
    query = filter.apply_to(Partner)
    assert_equal(4, query.count)

    # returns only partners assigned category (in include mode)
    partner1.tags << @category

    filter = PartnerCategoryFilter.new(category: @category.id)
    query = filter.apply_to(Partner)
    assert_equal(1, query.count)

    # returns only partners NOT assigned category (in exclude mode)
    filter = PartnerCategoryFilter.new(category: @category.id, mode: 'exclude')
    query = filter.apply_to(Partner)
    assert_equal(3, query.count)
  end

  test '#show_filter?' do
    # is false if no partnered categories found
    filter = PartnerCategoryFilter.new({})
    assert_not_predicate(filter, :show_filter?)

    # is true when partnered categories found
    given_some_partnered_categories_exist

    filter = PartnerCategoryFilter.new({})
    assert_predicate filter, :show_filter?
  end

  test '#current_category?' do
    # is false when no current category set
    filter = PartnerCategoryFilter.new({})
    assert_not(filter.current_category?(@category))

    # is true when current category matches incoming category
    filter = PartnerCategoryFilter.new(category: @category.id)
    assert(filter.current_category?(@category))
  end

  test 'modes' do
    # default to include mode
    filter = PartnerCategoryFilter.new({})
    assert_predicate filter, :include_mode?
    assert_not filter.exclude_mode?

    # is include mode when set
    filter = PartnerCategoryFilter.new(mode: 'include')
    assert_predicate filter, :include_mode?
    assert_not filter.exclude_mode?

    # is exclude mode when set
    filter = PartnerCategoryFilter.new(mode: 'exclude')
    assert_predicate filter, :exclude_mode?
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
