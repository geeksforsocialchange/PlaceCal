require 'test_helper'

class TurfTest < ActiveSupport::TestCase
  setup do
    @turf = create(:turf)
    @user = create(:user)
  end

  test 'updates user roles when saved' do
    assert_nil @user.role
    @turf.users << @user
    @turf.save
    assert_equal @user.role, 'turf_admin'
  end
end
