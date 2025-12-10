# frozen_string_literal: true

require 'test_helper'

class DeviseUserInvitationMailerTest < ActiveSupport::TestCase
  include EmailHelper

  test 'inviting a user sends an email' do
    user = User.new(email: 'user@example.com')
    user.password = user.password_confirmation = 'password'
    user.save!
    user.invite!

    last_email = last_email_delivered
    assert_predicate last_email, :present?, 'Expected an email to be sent when inviting a user'
  end
end
