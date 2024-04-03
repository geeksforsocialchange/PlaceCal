# frozen_string_literal: true

require 'test_helper'

class PartnerFiltersTest < ActiveSupport::TestCase
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
    @filters = PartnerFilters.new(@site, [], {})
  end

  test '#active?' do
    # is false by default
    assert_not_predicate(@filters, :category_active?, 'is_active? should be false with no input')
    filters = PartnerFilters.new(@site, [], category: @category.id)
    assert_predicate filters, :category_active?, 'should be active'
  end

  test '#categories - no partners or tags' do
    # no partners or tags
    #   -> empty set
    found = @filters.categories
    assert_predicate found.length, :zero?
  end

  test '#categories - partners exist on the site but are untagged' do
    # partners exist on the site but are untagged
    #   -> empty set
    partner = build(:partner, address: nil)
    partner.address = build(:address, postcode: 'M15 5DD')
    partner.service_areas.build(neighbourhood: @neighbourhood2)
    partner.save!

    found = @filters.categories
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

    found = @filters.categories
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

    found = @filters.categories
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

    found = @filters.categories
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

    filters = PartnerFilters.new(new_site, [], {})
    found = filters.categories

    # found tag from partner in child neighbourhood
    assert_equal(1, found.length)
  end

  test '#apply_to categories' do
    Partner.destroy_all

    partner1 = create(:partner)
    partner2 = create(:partner)
    partner3 = create(:partner)
    partner4 = create(:partner)

    # returns every partner if no filter category set
    query = @filters.apply_to(Partner)
    assert_equal(4, query.count)

    # returns only partners assigned category (in include mode)
    partner1.tags << @category

    filters = PartnerFilters.new(@site, [], category: @category.id)
    query = filters.apply_to(Partner)
    assert_equal(1, query.count)

    # returns only partners NOT assigned category (in exclude mode)
    filters = PartnerFilters.new(@site, [], category: @category.id, category_mode: 'exclude')
    query = filters.apply_to(Partner)
    assert_equal(3, query.count)
  end

  test '#apply_to neighbourhoods' do
    Partner.destroy_all

    partner1 = create(:moss_side_partner)
    partner2 = create(:ashton_partner)

    # returns every partner if no filter neighbourhood set
    neighbourhood_filters = PartnerFilters.new(@site, [], {})
    query = neighbourhood_filters.apply_to(Partner)
    assert_equal(2, query.count)

    # # returns only partners assigned neighbourhood name
    filters = PartnerFilters.new(@site, [], neighbourhood_name: 'Ashton Hurst')
    query = filters.apply_to(Partner.all)
    assert_equal(1, query.count)
  end

  test '#apply_to neighbourhoods and categories' do
    Partner.destroy_all

    partner1 = create(:moss_side_partner)
    partner2 = create(:ashton_partner)
    partner2.tags << @category

    # returns every partner if no filters set
    filters = PartnerFilters.new(@site, [], {})
    query = filters.apply_to(Partner)
    assert_equal(2, query.count)

    # returns only partners assigned neighbourhood name and category
    filters = PartnerFilters.new(@site, [], neighbourhood_name: 'Ashton Hurst', category: @category.id)
    query = filters.apply_to(Partner)
    assert_equal(1, query.count)

    # returns only partners matching both filters
    category_b = create(:category)
    filters = PartnerFilters.new(@site, [], neighbourhood_name: 'Ashton Hurst', category: category_b.id)
    query = filters.apply_to(Partner)
    assert_equal(0, query.count)
  end

  test '#show_category_filter?' do
    # is false if no partnered categories found
    assert_not_predicate(@filters, :show_category_filter?)

    # is true when partnered categories found
    given_some_partnered_categories_exist

    filters = PartnerFilters.new(@site, [], {})
    assert_predicate filters, :show_category_filter?
  end

  test '#current_category?' do
    # is false when no current category set
    assert_not(@filters.current_category?(@category))

    # is true when current category matches incoming category
    filters = PartnerFilters.new(@site, [], category: @category.id)
    assert(filters.current_category?(@category))
  end

  test 'modes' do
    # default to include mode
    assert_predicate @filters, :include_mode?
    assert_not @filters.exclude_mode?

    # is include mode when set
    filters = PartnerFilters.new(@site, [], category_mode: 'include')
    assert_predicate filters, :include_mode?
    assert_not filters.exclude_mode?

    # is exclude mode when set
    filters = PartnerFilters.new(@site, [], category_mode: 'exclude')
    assert_predicate filters, :exclude_mode?
    assert_not filters.include_mode?
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
