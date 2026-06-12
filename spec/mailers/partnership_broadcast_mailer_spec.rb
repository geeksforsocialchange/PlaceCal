# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnershipBroadcastMailer, type: :mailer do
  let(:broadcast) { create(:partnership_broadcast, subject: "Network news", body: "Big update.\n\nSecond paragraph.") }
  let(:user) do
    create(:user).tap do |u|
      EmailSubscription.set(u, :partnership_updates, true, source: :profile_page)
    end
  end

  it "sends the broadcast with the sender as reply-to" do
    email = described_class.broadcast(user, broadcast)

    expect(email.subject).to eq "Network news"
    expect(email.reply_to).to eq [broadcast.sender.email]
    expect(email.parts.map(&:mime_type)).to contain_exactly("text/html", "text/plain")
    email.parts.each do |part|
      expect(part.decoded).to include("Big update.")
      expect(part.decoded).to include("email-preferences")
    end
  end

  it "is suppressed for users who have not opted in (guard backstop)" do
    not_opted = create(:user)

    expect { described_class.broadcast(not_opted, broadcast).deliver_now }
      .not_to change(ActionMailer::Base.deliveries, :count)
  end

  it "delivers to opted-in users" do
    expect { described_class.broadcast(user, broadcast).deliver_now }
      .to change(ActionMailer::Base.deliveries, :count).by(1)
  end
end
