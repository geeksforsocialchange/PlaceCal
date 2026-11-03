# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organiser-written markdown", type: :request do
  let(:site) { create(:site, slug: "test-site", description: "About **us**\n\n- One\n- Two") }
  let(:ward) { create(:riverside_ward) }
  let(:address) { create(:address, neighbourhood: ward) }
  let(:partner) { create(:partner, address:, description: "- First\n- Second", accessibility_info: "- Step-free") }
  let(:host) { "#{site.slug}.lvh.me" }

  before { site.neighbourhoods << ward }

  def markdown_lists
    response.parsed_body.css(".markdown-content ul")
  end

  it "styles an event's description" do
    event = create(:event, organiser: partner, address:, dtstart: 1.day.from_now, description: "- One\n- Two")
    get event_url(event, host:)

    expect(response.parsed_body.at_css('[data-scope="event-details"][data-part="description"].markdown-content ul')).to be_present
  end

  it "styles a partner's description and accessibility info" do
    get partner_url(partner, host:)

    expect(response.parsed_body.at_css('[data-scope="partner-details"][data-part="description"].markdown-content ul')).to be_present
    expect(response.parsed_body.at_css("details.markdown-content ul")).to be_present
  end

  it "styles a news article's body" do
    article = create(:article, is_draft: false, body: "Intro\n\n- One\n- Two")
    article.partners << partner
    get news_url(article, host:)

    expect(response.parsed_body.at_css('[data-scope="article"][data-part="content"].markdown-content ul')).to be_present
  end

  it "styles the site's description on its homepage" do
    get root_url(host:)

    expect(markdown_lists.map { it.css("li").map(&:text) }).to include(%w[One Two])
  end
end
