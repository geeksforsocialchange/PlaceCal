# frozen_string_literal: true

require 'test_helper'

class TagTest < ActiveSupport::TestCase
  setup do
    @tag = create(:tag)
    @user = create(:user)
    @partner = create(:partner)
  end

  test 'updates user roles when saved' do
    @tag.users << @user
    @tag.save
    assert_predicate @user, :tag_admin?
  end

  test 'updates partners tags when saved' do
    @tag.partners << @partner
    @tag.save

    assert_predicate @tag.partners.length, :positive?
  end

  test 'system_tags cannot modify name or slug' do
    @tag.system_tag = true
    @tag.name = 'This is a new name'
    @tag.slug = 'a-new-tag-slug'

    assert_not @tag.validate

    assert @tag.errors.key?(:name)
    assert @tag.errors.key?(:slug)
  end

  #   test 'must have type' do
  #     tag = Tag.new(name: 'tag', slug: 'tag', type: nil)
  #     assert_not tag.valid?
  #
  #     type_problem = tag.errors[:type]
  #     assert_predicate type_problem, :present?
  #     assert_equal 'Tags must be of type Category, Facility or Partnership', type_problem.first
  #   end
  #
  #   test 'types of tag can be instantiated' do
  #     Tag.destroy_all
  #
  #     partnership_tag = Tag.create!(name: '0 partnership', slug: 'partnership_tag', type: 'PartnershipTag')
  #     facility_tag = Tag.create!(name: '1 facility', slug: 'facility_tag', type: 'FacilityTag')
  #     category_tag = Tag.create!(name: '2 category', slug: 'category_tag', type: 'CategoryTag')
  #
  #     found = Tag.order(:name).all
  #     assert_equal 3, found.length
  #
  #     assert found[0].is_a?(PartnershipTag)
  #     assert found[1].is_a?(FacilityTag)
  #     assert found[2].is_a?(CategoryTag)
  #   end
  #
  #   test 'uniqueness scoping on name and slug' do
  #     Tag.destroy_all
  #
  #     # different tag types with identical values
  #     Tag.create! name: 'tag-name', slug: 'tag-slug', type: 'FacilityTag'
  #     Tag.create! name: 'tag-name', slug: 'tag-slug', type: 'CategoryTag'
  #
  #     assert_equal 2, Tag.count, 'expecting 2 tags to be counted'
  #
  #     # now try to create an actually identical tag
  #     assert_raises(ActiveRecord::RecordInvalid) do
  #       Tag.create! name: 'tag-name', slug: 'tag-slug', type: 'FacilityTag'
  #     end
  #   end
end
