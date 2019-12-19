# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test 'updates user role on save' do
    # To start with, role is nil
    assert_nil @user.role

    # If we add a partner, role is partner_admin
    @user.partners << create(:partner)
    @user.save
    assert_equal 'partner_admin', @user.role

    # If we add a tag, role is tag_admin (note this overrides above)
    @user.tags << create(:tag)
    @user.save
    assert_equal 'tag_admin', @user.role

    # Root users don't get overwritten
    @user.role = 'root'
    @user.save
    assert_equal 'root', @user.role
  end

  test 'full name method gives sensible responses' do
    @user.update(first_name: 'Joan', last_name: '')
    assert_equal 'Joan', @user.full_name
    @user.update(first_name: '', last_name: 'Jones')
    assert_equal 'Jones', @user.full_name
    @user.update(first_name: 'Joan', last_name: 'Jones')
    assert_equal 'Joan Jones', @user.full_name
  end

  test 'admin name method gives sensible responses' do
    @user.update(first_name: 'Joan', last_name: '')
    assert_equal "Joan <#{@user.email}>", @user.admin_name
    @user.update(first_name: '', last_name: 'Jones')
    assert_equal "JONES <#{@user.email}>", @user.admin_name
    @user.update(first_name: 'Joan', last_name: 'Jones')
    assert_equal "JONES, Joan <#{@user.email}>", @user.admin_name
  end
end
