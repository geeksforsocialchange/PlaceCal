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
    assert @user.tag_admin?
  end

  test 'updates partners tags when saved' do
    @tag.partners << @partner
    @tag.save

    assert @tag.partners.length > 0
  end

  test 'system_tags cannot modify name or slug' do
    @tag.system_tag = true
    @tag.name = 'This is a new name'
    @tag.slug = 'a-new-tag-slug'

    refute @tag.validate

    assert @tag.errors.has_key?(:name)
    assert @tag.errors.has_key?(:slug)
  end
end
