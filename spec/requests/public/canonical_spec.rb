# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Default canonical URLs", type: :request do
  let!(:site) { create(:site, slug: "test-site") }
  let(:base) { "http://test-site.lvh.me" }

  def canonical = Nokogiri::HTML(response.body).at_css("link[rel='canonical']")["href"]

  it "keeps the homepage's slash" do
    get "#{base}/"
    expect(canonical).to eq("#{base}/")
  end

  it "drops a trailing slash" do
    get "#{base}/events/"
    expect(canonical).to eq("#{base}/events")
  end

  it "drops params that don't change the page" do
    get "#{base}/?trk=organization_guest_main-feed-card-text&utm_source=x"
    expect(canonical).to eq("#{base}/")
  end

  it "keeps params that do, including ones it hasn't met" do
    get "#{base}/events?period=week&audience=families&fbclid=abc"
    expect(canonical).to eq("#{base}/events?audience=families&period=week")
  end

  it "keeps a region the site has, and drops one it doesn't" do
    site.tags << create(:partnership, name: "London", slug: "london")

    get "#{base}/events?region=london"
    expect(canonical).to eq("#{base}/events?region=london")

    get "#{base}/events?region=trans-dimension"
    expect(canonical).to eq("#{base}/events")
  end
end
