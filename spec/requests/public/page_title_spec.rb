# frozen_string_literal: true

require "rails_helper"

# `content_for(:title)` is captured through Phlex and comes back escaped, so
# composing the <title> out of it used to escape a second time and put the
# literal text "Children&#39;s Storytime" in the browser tab and the SERP.
RSpec.describe "Public page titles", type: :request do
  let(:site) { create(:site, slug: "titles") }
  let(:ward) { create(:riverside_ward) }
  let(:address) { create(:address, neighbourhood: ward) }
  let(:partner) { create(:partner, address: address) }
  let(:event) do
    create(:event, organiser: partner, address: address, summary: "Children's Storytime", dtstart: 1.day.from_now)
  end

  before do
    site.neighbourhoods << ward
    get event_url(event, host: "#{site.slug}.lvh.me")
  end

  def title_tag
    response.body[%r{<title>.*?</title>}m]
  end

  it "escapes an apostrophe in the title exactly once" do
    expect(title_tag).to include("&#39;")
    expect(title_tag).not_to include("&amp;#39;")
  end

  it "reads back as the original summary once unescaped" do
    expect(CGI.unescapeHTML(title_tag.sub("<title>", "").sub("</title>", ""))).to start_with("Children's Storytime")
  end

  # Phlex escapes attributes on its own terms, so og:title carries a bare
  # apostrophe. What matters is that it says the same thing as <title>.
  it "agrees with og:title" do
    og_title = CGI.unescapeHTML(response.body[/<meta property="og:title" content="([^"]*)"/, 1])

    expect(og_title).to start_with("Children's Storytime")
    expect(og_title).not_to include("&#39;")
  end
end
