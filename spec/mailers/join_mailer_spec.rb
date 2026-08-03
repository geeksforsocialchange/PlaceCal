# frozen_string_literal: true

require "rails_helper"

RSpec.describe JoinMailer do
  describe "#join_us" do
    let(:contact_request) do
      ContactRequest.new(
        name: "Test User", email: "test@example.com", why: "Community",
        ringback: "1", more_info: "0"
      )
    end

    let(:mail) { described_class.join_us(contact_request) }

    it "sends the enquiry to support" do
      expect(mail.to).to eq(["support@placecal.org"])
      expect(mail.subject).to eq("New Join Request")
    end

    it "reports the checkbox choices from their boolean casts" do
      body = mail.body.encoded
      expect(body).to match(/A ring back.*Yes/i)
      expect(body).to match(/More information.*No/i)
    end

    it "includes the enquirer's details" do
      expect(mail.body.encoded).to include("Test User", "test@example.com", "Community")
    end
  end
end
