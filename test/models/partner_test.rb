# frozen_string_literal: true

require 'test_helper'

class PartnerTest < ActiveSupport::TestCase
  setup do
    @partner = create(:partner)
    @user = create(:user)
  end

  test 'updates user roles when saved' do
    assert_nil @user.role
    @partner.users << @user
    @partner.save
    assert_equal @user.role, 'partner_admin'
  end
end
