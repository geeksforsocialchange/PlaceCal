# frozen_string_literal: true

require "rails_helper"

RSpec.describe SocialLink do
  describe "platform detection" do
    {
      "https://www.facebook.com/HulmeCommunity" => [:facebook, "Facebook", "HulmeCommunity", :contact_facebook],
      "https://www.facebook.com/groups/hulmecommunity/" => [:facebook, "Facebook", nil, :contact_facebook],
      "https://www.facebook.com/profile.php?id=100064" => [:facebook, "Facebook", nil, :contact_facebook],
      "https://m.facebook.com/HulmeCommunity" => [:facebook, "Facebook", "HulmeCommunity", :contact_facebook],
      "https://fb.com/HulmeCommunity" => [:facebook, "Facebook", "HulmeCommunity", :contact_facebook],
      "https://www.instagram.com/hulmecc/" => [:instagram, "Instagram", "@hulmecc", :contact_instagram],
      "https://bsky.app/profile/hulmecc.bsky.social" => [:bluesky, "Bluesky", "hulmecc.bsky.social", :contact_bluesky],
      "https://bsky.app/profile/hulme.example.org" => [:bluesky, "Bluesky", "hulme.example.org", :contact_bluesky],
      "https://mastodon.social/@hulmecc" => [:mastodon, "Mastodon", "@hulmecc@mastodon.social", :contact_mastodon],
      "https://social.coop/@hulmecc" => [:mastodon, "Mastodon", "@hulmecc@social.coop", :contact_mastodon],
      "https://toot.example.org/@hulmecc@social.coop" => [:mastodon, "Mastodon", "@hulmecc@social.coop", :contact_mastodon],
      "https://www.tiktok.com/@hulmecc" => [:tiktok, "TikTok", "@hulmecc", :contact_tiktok],
      "https://www.youtube.com/@hulmecc" => [:youtube, "YouTube", "@hulmecc", :contact_youtube],
      "https://www.youtube.com/channel/UC123" => [:youtube, "YouTube", nil, :contact_youtube],
      "https://www.linkedin.com/company/hulmecc" => [:linkedin, "LinkedIn", nil, :contact_linkedin],
      "https://www.threads.net/@hulmecc" => [:threads, "Threads", "@hulmecc", :contact_threads],
      "https://x.com/hulmecc" => [:x, "X", "@hulmecc", :contact_x],
      "https://twitter.com/hulmecc" => [:x, "X", "@hulmecc", :contact_x],
      "https://www.fedex.com/@hulmecc" => [:mastodon, "Mastodon", "@hulmecc@fedex.com", :contact_mastodon],
      "https://chat.whatsapp.com/AbCdEf123" => [:whatsapp, "WhatsApp", nil, :contact_whatsapp],
      "https://whatsapp.com/channel/0029Va" => [:whatsapp, "WhatsApp", nil, :contact_whatsapp],
      "https://t.me/hulmecc" => [:telegram, "Telegram", "@hulmecc", :contact_telegram],
      "https://discord.gg/AbCdEf" => [:discord, "Discord", nil, :contact_discord],
      "https://linktr.ee/hulmecc" => [:linktree, "Linktree", "@hulmecc", :contact_linktree],
      "https://pixelfed.social/hulmecc" => [:pixelfed, "Pixelfed", "@hulmecc", :contact_pixelfed],
      "https://hulmecc.bandcamp.com/" => [:bandcamp, "Bandcamp", nil, :contact_bandcamp],
      "https://soundcloud.com/hulmecc" => [:soundcloud, "SoundCloud", "@hulmecc", :contact_soundcloud],
      "https://www.twitch.tv/hulmecc" => [:twitch, "Twitch", "@hulmecc", :contact_twitch],
      "https://vimeo.com/123456789" => [:vimeo, "Vimeo", nil, :contact_vimeo],
      "https://medium.com/@hulmecc" => [:link, "medium.com", nil, :link],
      "https://substack.com/@hulmecc" => [:link, "substack.com", nil, :link],
      "https://www.facebook.com/Café-Hulme" => [:facebook, "Facebook", nil, :contact_facebook],
      "https://hulme.example.org:8443/newsletter#latest" => [:link, "hulme.example.org", nil, :link],
      "https://hulme.example.org/newsletter" => [:link, "hulme.example.org", nil, :link],
      "https://www.fedex.com/en-gb/home.html" => [:link, "fedex.com", nil, :link]
    }.each do |url, (platform, name, handle, icon)|
      it "recognises #{url}" do
        link = described_class.new(url)

        expect([link.platform, link.name, link.handle, link.icon]).to eq([platform, name, handle, icon])
      end
    end

    it "checks known hosts before the fediverse path, so @names elsewhere keep their network" do
      expect(described_class.new("https://www.tiktok.com/@hulmecc").platform).to eq(:tiktok)
    end

    it "matches whole host labels, so x.com doesn't claim other domains ending in x.com" do
      expect(described_class.new("https://netflix.com/hulmecc").platform).to eq(:link)
    end
  end

  it "accepts addresses with accented letters, which URI.parse rejects" do
    expect(described_class.valid_url?("https://www.facebook.com/Café-Hulme")).to be true
    expect(described_class.new("https://www.facebook.com/Café-Hulme").label).to eq("facebook.com/Café-Hulme")
  end

  describe "#label" do
    it "is the handle when there is one" do
      expect(described_class.new("https://www.instagram.com/hulmecc/").label).to eq("@hulmecc")
    end

    it "is the address without its scheme, www or trailing slash otherwise" do
      expect(described_class.new("https://www.facebook.com/groups/hulme/").label).to eq("facebook.com/groups/hulme")
      expect(described_class.new("https://www.facebook.com/profile.php?id=1").label).to eq("facebook.com/profile.php?id=1")
    end
  end

  describe "with an address that isn't a web link" do
    ["not-a-url", "ftp://example.org/hulme", "javascript:alert(1)", "https://", "https://user@example.org", "https://example.org/a b"].each do |value|
      it "treats #{value.inspect} as an unrecognised link without raising" do
        link = described_class.new(value)

        expect(link.platform).to eq(:link)
        expect(link.handle).to be_nil
        expect(link.label).to eq(value)
        expect(described_class.valid_url?(value)).to be false
      end
    end
  end

  describe ".detection_rules" do
    it "maps every known host to its network name, plus the fediverse name" do
      rules = described_class.detection_rules

      expect(rules[:hosts]).to include("bsky.app" => "Bluesky", "twitter.com" => "X", "fb.com" => "Facebook")
      expect(rules[:fediverse]).to eq("Mastodon")
      expect(rules[:not_fediverse]).to eq(%w[medium.com substack.com])
    end
  end
end
