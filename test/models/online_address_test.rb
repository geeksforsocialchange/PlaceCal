# frozen_string_literal: true

require "test_helper"

class AddressTest < ActiveSupport::TestCase
  test "can create online address with event" do
    event = create(:event)
    online_address = create(:online_address)
    online_address.events << event
    online_address.save!

    assert_equal event.online_address.id, online_address.id
    assert_equal online_address.events.first.id, event.id
  end
end
