# frozen_string_literal: true

require "rails_helper"

# Previews break silently when a component's props change, so render every one.
RSpec.describe "Lookbook previews", type: :request do
  def lookbook_links(path, depth)
    get path
    follow_redirect! while response.redirect?
    Nokogiri::HTML(response.body).css("a[href^='/lookbook/']").map { it["href"].split("?").first }
            .select { it.count("/") == depth }.uniq
  end

  def render_failure(path)
    get path
    "#{path} returned #{response.status}" unless response.successful?
  rescue StandardError => e
    "#{path} raised #{e.class}: #{e.message.lines.first&.strip}"
  end

  it "renders every scenario" do
    scenarios = lookbook_links("/lookbook", 4)
    expect(scenarios.size).to be > 50

    expect(scenarios.filter_map { render_failure("#{it}/preview") }).to be_empty
  end

  it "renders a preview under every installed theme" do
    failures = PlaceCal::Extensions.theme_names.filter_map do |theme|
      render_failure("/lookbook/previews/event/list_view/preview?_display=#{CGI.escape({ theme: }.to_json)}")
    end

    expect(failures).to be_empty
  end

  it "keeps directory previews off local-site themes" do
    get "/lookbook/previews/directory_footer/default/preview?_display=#{CGI.escape({ theme: 'transdimension' }.to_json)}"
    expect(response).to be_successful
    expect(response.body).not_to include("transdimension/theme")

    get "/lookbook/previews/event/list_view/preview?_display=#{CGI.escape({ theme: 'transdimension' }.to_json)}"
    expect(response.body).to include("transdimension/theme")
  end

  it "shows every scenario on a component's own page" do
    get "/lookbook/previews/event"
    expect(response).to be_successful
    expect(Nokogiri::HTML(response.body).css("lookbook-embed").map { it["scenario"] })
      .to contain_exactly("list_view", "page_view", "online_event", "repeating_event")
  end

  it "opens on the overview page, and the overview renders" do
    get "/lookbook"
    expect(response).to redirect_to(%r{/lookbook/pages/overview})

    follow_redirect!
    expect(response).to be_successful
    expect(response.body).to include("lookbook-embed")
  end
end
