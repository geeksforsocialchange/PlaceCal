# frozen_string_literal: true

require 'test_helper'

class TagTest < ActiveSupport::TestCase
  setup do
    create_typed_tags
    @tag = Tag.first
    @partnership_tag = Tag.where(type: 'Partnership').first
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

  test 'a root user can access all tags' do
    root_user = create :root
    assert_equal Tag.users_tags(root_user), Tag.all
  end

  test 'a tag_admin can access their own Partnership tag but not others' do
    @partnership_tag.users << @user
    @partnership_tag.save

    Tag.users_tags(@user).each do |t|
      assert_equal t.name, @partnership_tag.name if t.type == 'Partnership'
    end
  end

  test 'a tag_admin can access Facility tags' do
    @partnership_tag.users << @user
    @partnership_tag.save

    facility_tag = Tag.where(type: 'Facility').first

    Tag.users_tags(@user).each do |t|
      assert_equal t.name, facility_tag.name if t.type == 'Facility'
    end
  end

  test 'a tag_admin can access Category tags' do
    @partnership_tag.users << @user
    @partnership_tag.save

    category_tag = Tag.where(type: 'Category').first

    Tag.users_tags(@user).each do |t|
      assert_equal t.name, category_tag.name if t.type == 'Category'
    end
  end

  test 'a non tag_admin cannot access any Partnership tags' do
    assert_equal(0, Tag.users_tags(@user).where(type: 'Partnership').count)
  end

  test 'a regular user can access Facility tags' do
    facility_tag = Tag.where(type: 'Facility').first

    Tag.users_tags(@user).each do |t|
      assert_equal t.name, facility_tag.name if t.type == 'Facility'
    end
  end

  test 'a regular user can access Category tags' do
    category_tag = Tag.where(type: 'Category').first

    Tag.users_tags(@user).each do |t|
      assert_equal t.name, category_tag.name if t.type == 'Category'
    end
  end
end
