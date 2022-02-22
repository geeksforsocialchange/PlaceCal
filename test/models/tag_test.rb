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
end
