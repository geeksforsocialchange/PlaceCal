# frozen_string_literal: true

require 'test_helper'

class TagTest < ActiveSupport::TestCase
  setup do
    @tag = create(:tag)
    @user = create(:user)
  end

  test 'updates user roles when saved' do
    @tag.users << @user
    @tag.save
    assert @user.tag_admin?
  end
end
