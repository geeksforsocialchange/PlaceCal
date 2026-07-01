# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnershipBroadcast, type: :model do
  let(:partnership) { create(:partnership) }
  let(:sender) { create(:root_user) }

  def build_broadcast(**attrs)
    described_class.new(partnership: partnership, sender: sender,
                        subject: "Hello", body: "An update", **attrs)
  end

  it "requires subject, body and a sender at creation" do
    expect(build_broadcast).to be_valid
    expect(build_broadcast(subject: "")).not_to be_valid
    expect(build_broadcast(body: "")).not_to be_valid
    expect(build_broadcast(sender: nil)).not_to be_valid
  end

  describe "daily cap" do
    it "allows only one broadcast per partnership per day" do
      build_broadcast.save!

      blocked = build_broadcast(subject: "Another")
      expect(blocked).not_to be_valid
      expect(blocked.errors[:base].join).to match(/one broadcast/i)
    end

    it "does not cap other partnerships" do
      build_broadcast.save!

      other = described_class.new(partnership: create(:partnership), sender: sender,
                                  subject: "Hello", body: "An update")
      expect(other).to be_valid
    end
  end

  it "keeps the log when the sender's account is erased" do
    broadcast = build_broadcast.tap(&:save!)

    sender.destroy!

    expect(broadcast.reload.sender).to be_nil
    expect(broadcast.subject).to eq "Hello"
  end
end
