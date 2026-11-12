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

  describe ".service_for" do
    it "names known hosts, with or without a subdomain" do
      expect(described_class.service_for("https://meet.google.com/abc-defg-hij")).to eq(:google_meet)
      expect(described_class.service_for("https://us02web.zoom.us/j/123")).to eq(:zoom)
      expect(described_class.service_for("https://www.youtube.com/live/abc")).to eq(:youtube)
      expect(described_class.service_for("https://DISCORD.GG/abc")).to eq(:discord)
    end

    it "matches the whole host, not a substring of it" do
      expect(described_class.service_for("https://notzoom.us/j/123")).to be_nil
      expect(described_class.service_for("https://example.org/?next=zoom.us")).to be_nil
    end

    it "gives nil for an unknown, malformed or hostless URL" do
      expect(described_class.service_for("https://www.eventbrite.co.uk/e/123")).to be_nil
      expect(described_class.service_for("https://exa mple.org")).to be_nil
      expect(described_class.service_for("zoom.us/j/123")).to be_nil
      expect(described_class.service_for(nil)).to be_nil
    end
  end

  it "keeps the importer's domain list and its search order" do
    expect(described_class::DOMAINS).to eq(%w[
                                             meet.jit.si meet.google.com zoom.us teams.microsoft.com teams.live.com webex.com gotomeet.me gotomeeting.com
                                             discord.gg discord.com youtube.com youtu.be twitch.tv vimeo.com facebook.com fb.watch instagram.com linkedin.com
                                             crowdcast.io streamyard.com hopin.com
                                           ])
  end

  it "has a display name for every service" do
    described_class::SERVICES.each_key do |service|
      expect(I18n.t("online_address.services.#{service}", default: nil)).to be_present, "no name for #{service}"
    end
  end

  describe "#service_name and #stream?" do
    it "names a meeting service" do
      online_address = described_class.new(url: "https://teams.microsoft.com/l/meetup-join/1")
      expect(online_address.service_name).to eq("Microsoft Teams")
      expect(online_address.stream?).to be(false)
    end

    it "marks a streaming service" do
      expect(described_class.new(url: "https://twitch.tv/placecal")).to be_stream
    end

    it "gives nothing for an unknown host" do
      online_address = described_class.new(url: "https://example.org/live")
      expect(online_address.service_name).to be_nil
      expect(online_address).not_to be_stream
    end
  end
end
