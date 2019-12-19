# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test 'updates user role on save' do
    # Does this person manage at least one partner?
    @user.partners << create(:partner)
    @user.save
    assert @user.partner_admin?

    # Does this person manage at least one tag?
    @user.tags << create(:tag)
    @user.save
    assert @user.tag_admin?

    # Is this person a root? If they are, they're also a secretary
    @user.update(role: :root)
    assert @user.root?
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
