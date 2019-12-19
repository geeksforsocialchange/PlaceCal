# frozen_string_literal: true

require 'test_helper'

class TagTest < ActiveSupport::TestCase
  setup do
    @tag = create(:tag)
    @user = create(:user)
  end

  test 'updates user roles when saved' do
    assert_nil @user.role
    @tag.users << @user
    @tag.save
    assert_equal @user.role, 'tag_admin'
  end
end
