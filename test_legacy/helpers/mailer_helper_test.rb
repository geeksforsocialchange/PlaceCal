# frozen_string_literal: true

require 'test_helper'

class MailerHelperTest < ActiveSupport::TestCase
  class MailerView
    include MailerHelper
  end

  setup do
    @view = MailerView.new
  end

  test '#greeting_text' do
    user = User.new

    # with no set name
    output = @view.greeting_text(user)
    assert_equal 'Hello', output

    # with just first name
    user.first_name = 'Alpha'
    output = @view.greeting_text(user)
    assert_equal 'Hello Alpha', output

    # with just last name
    user.first_name = ''
    user.last_name = 'Beta'
    output = @view.greeting_text(user)
    assert_equal 'Hello Beta', output

    # with all name
    user.first_name = 'Cappa'
    user.last_name = 'Beta'
    output = @view.greeting_text(user)
    assert_equal 'Hello Cappa Beta', output
  end
end
