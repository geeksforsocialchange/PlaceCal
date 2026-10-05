# frozen_string_literal: true

# == Schema Information
#
# Table name: online_addresses
#
#  id         :bigint           not null, primary key
#  link_type  :string
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe OnlineAddress do
  describe "event association" do
    it "can create online address with event" do
      VCR.use_cassette(:import_test_calendar) do
        event = create(:event)
        online_address = create(:online_address)
        online_address.events << event
        online_address.save!

        expect(event.online_address.id).to eq(online_address.id)
        expect(online_address.events.first.id).to eq(event.id)
      end
    end
  end
end
