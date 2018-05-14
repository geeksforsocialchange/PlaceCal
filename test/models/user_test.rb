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

    # If we add a turf, role is turf_admin (note this overrides above)
    @user.turfs << create(:turf)
    @user.save
    assert_equal 'turf_admin', @user.role

    # Root users don't get overwritten
    @user.role = 'root'
    @user.save
    assert_equal 'root', @user.role
  end
end
