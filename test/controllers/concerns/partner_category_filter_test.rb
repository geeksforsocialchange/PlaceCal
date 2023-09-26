# frozen_string_literal: true

require 'test_helper'

class PartnerCategoryFilterTest < ActiveSupport::TestCase
  setup do
    Neighbourhood.destroy_all

    @category = create(:category)
    @categories = create_list(:category, 4)
    @categories << @category

    @neighbourhood1 = create(
      :bare_neighbourhood, # M15 5DD
      name: 'Hulme Longname',
      name_abbr: 'Hulme',
      unit: 'ward',
      unit_code_key: 'WD19CD',
      unit_code_value: 'E05011368',
      unit_name: 'Hulme',
      release_date: DateTime.new(2023, 7)
    )
    assert_predicate @neighbourhood1, :valid?

    @neighbourhood2 = create(
      :bare_neighbourhood, # OL6 8BH
      name: 'Ashton Hurst',
      name_abbr: 'Ashton Hurst',
      unit: 'ward',
      unit_code_key: 'WD19CD',
      unit_code_value: 'E05000800',
      unit_name: 'Ashton Hurst',
      release_date: DateTime.new(2023, 7)
    )
    assert_predicate @neighbourhood2, :valid?

    @other_neighbourhood = create(
      :bare_neighbourhood, # M16 7BA
      name: 'Moss Side',
      name_abbr: 'Moss Side',
      unit: 'ward',
      unit_code_key: 'WD19CD',
      unit_code_value: 'E05011372',
      unit_name: 'Moss Side',
      release_date: DateTime.new(2023, 7)
    )
    assert_predicate @other_neighbourhood, :valid?

    @site = create(:site)
    @site.neighbourhoods << @neighbourhood1
    @site.neighbourhoods << @neighbourhood2
  end

  test '#active?' do
    # is false by default
    filter = PartnerCategoryFilter.new(@site, {})
    assert_not_predicate(filter, :active?, 'is_active? should be false with no input')
    filter = PartnerCategoryFilter.new(@site, category: @category.id)
    assert_predicate filter, :active?, 'should be active'
  end

  test '#categories - no partners or tags' do
    # no partners or tags
    #   -> empty set
    filter = PartnerCategoryFilter.new(@site, {})
    found = filter.categories
    assert_predicate found.length, :zero?
  end

  test '#categories - partners exist on the site but are untagged' do
    # partners exist on the site but are untagged
    #   -> empty set
    partner = build(:partner, address: nil)
    partner.address = build(:address, postcode: 'M15 5DD')
    partner.service_areas.build(neighbourhood: @neighbourhood2)
    partner.save!

    filter = PartnerCategoryFilter.new(@site, {})
    found = filter.categories
    assert_predicate found.length, :zero?
  end

  test '#categories - tagged partner with address in site' do
    # tagged partner with address in site
    #   -> tag of that partner

    # is found
    partner1 = build(:partner, address: nil)
    partner1.address = build(:address, postcode: 'M15 5DD')
    partner1.tags << @categories[0]
    partner1.save!

    # is not found
    partner2 = build(:partner, address: nil)
    partner2.address = build(:address, postcode: 'M16 7BA')
    partner2.tags << @categories[1]
    partner2.save!

    filter = PartnerCategoryFilter.new(@site, {})
    found = filter.categories
    assert_equal(1, found.length)
    assert_equal found.first.id, @categories[0].id
  end

  test '#categories - tagged partner with service area in site' do
    # tagged partner with service area in site
    #   -> tag of that partner
    # is found
    partner1 = build(:partner, address: nil)
    partner1.service_area_neighbourhoods << @neighbourhood1
    partner1.tags << @categories[0]
    partner1.save!

    # is not found
    partner2 = build(:partner, address: nil)
    partner2.service_area_neighbourhoods << @other_neighbourhood
    partner2.tags << @categories[1]
    partner2.save!

    filter = PartnerCategoryFilter.new(@site, {})
    found = filter.categories
    assert_equal(1, found.length)
    assert_equal found.first.id, @categories[0].id
  end

  test '#categories - tagged partners with both service areas and addresses' do
    # tagged partners with both service areas and addresses
    #   -> all the tags

    partner1 = build(:partner, address: nil)
    # partner1.service_area_neighbourhoods << @neighbourhood1
    partner1.service_areas.build(neighbourhood: @neighbourhood1)
    partner1.tags << @categories[0]
    partner1.save!

    # is also not found
    partner2 = build(:partner, address: nil)
    partner2.address = build(:address, postcode: 'OL6 8BH')
    partner2.tags << @categories[1]
    partner2.save!

    filter = PartnerCategoryFilter.new(@site, {})
    found = filter.categories
    assert_equal(2, found.length)

    assert_equal found.first.id, @categories[0].id
  end

  test '#categories - neighbourhood scope is hierarchical' do
    # if a partner is in a neighbourhood that is contained
    #   in another neighbourhood that the site owns,
    #   then the child neighbourhood partner should also
    #   be included in the search

    neighbourhood = create(:neighbourhood)
    parent = neighbourhood.parent

    new_site = create(:site)
    new_site.neighbourhoods << parent
    assert_predicate new_site, :valid?

    # has child neighbourhood
    partner = build(:partner, address: nil)
    partner.service_area_neighbourhoods << neighbourhood
    partner.tags << @categories[0]
    partner.save!

    filter = PartnerCategoryFilter.new(new_site, {})
    found = filter.categories

    # found tag from partner in child neighbourhood
    assert_equal(1, found.length)
  end

  test '#apply_to' do
    Partner.destroy_all

    partner1 = create(:partner)
    partner2 = create(:partner)
    partner3 = create(:partner)
    partner4 = create(:partner)

    # returns every partner if no filter category set
    filter = PartnerCategoryFilter.new(@site, {})
    query = filter.apply_to(Partner)
    assert_equal(4, query.count)

    # returns only partners assigned category (in include mode)
    partner1.tags << @category

    filter = PartnerCategoryFilter.new(@site, category: @category.id)
    query = filter.apply_to(Partner)
    assert_equal(1, query.count)

    # returns only partners NOT assigned category (in exclude mode)
    filter = PartnerCategoryFilter.new(@site, category: @category.id, category_mode: 'exclude')
    query = filter.apply_to(Partner)
    assert_equal(3, query.count)
  end

  test '#show_filter?' do
    # is false if no partnered categories found
    filter = PartnerCategoryFilter.new(@site, {})
    assert_not_predicate(filter, :show_filter?)

    # is true when partnered categories found
    given_some_partnered_categories_exist

    filter = PartnerCategoryFilter.new(@site, {})
    assert_predicate filter, :show_filter?
  end

  test '#current_category?' do
    # is false when no current category set
    filter = PartnerCategoryFilter.new(@site, {})
    assert_not(filter.current_category?(@category))

    # is true when current category matches incoming category
    filter = PartnerCategoryFilter.new(@site, category: @category.id)
    assert(filter.current_category?(@category))
  end

  test 'modes' do
    # default to include mode
    filter = PartnerCategoryFilter.new(@site, {})
    assert_predicate filter, :include_mode?
    assert_not filter.exclude_mode?

    # is include mode when set
    filter = PartnerCategoryFilter.new(@site, category_mode: 'include')
    assert_predicate filter, :include_mode?
    assert_not filter.exclude_mode?

    # is exclude mode when set
    filter = PartnerCategoryFilter.new(@site, category_mode: 'exclude')
    assert_predicate filter, :exclude_mode?
    assert_not filter.include_mode?
  end

  # helpers
  # rubocop:disable Minitest/TestMethodName, Lint/MissingCopEnableDirective
  def given_some_partnered_categories_exist
    assert_predicate @site.neighbourhoods.count, :positive?

    partner = create(:partner)
    partner.service_areas.create(neighbourhood: @site.neighbourhoods.first)

    @categories.each do |category|
      partner.tags << category
    end
  end
end
