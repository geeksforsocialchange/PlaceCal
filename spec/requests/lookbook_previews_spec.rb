# frozen_string_literal: true

require "rails_helper"

# Previews break silently when a component's props change, so render every one.
RSpec.describe "Lookbook previews", type: :request do
  def preview_path(lookup_path)
    Lookbook::Previews.all.find { it.lookup_path == lookup_path }.url_path
  end

  # Scenarios are the leaves of the preview tree: links no other link extends.
  def scenario_links
    get "/lookbook"
    follow_redirect! while response.redirect?
    links = Nokogiri::HTML(response.body).css("a[href^='/lookbook/previews/']").map { it["href"].split("?").first }.uniq
    links.reject { |link| links.any? { it.start_with?("#{link}/") } }
  end

  def render_failure(path)
    get path
    "#{path} returned #{response.status}" unless response.successful?
  rescue StandardError => e
    "#{path} raised #{e.class}: #{e.message.lines.first&.strip}"
  end

  it "gives every preview its own URL" do
    paths = Lookbook::Previews.all.map(&:url_path)

    expect(paths.tally.select { |_, count| count > 1 }).to be_empty
  end

  it "renders every scenario" do
    scenarios = scenario_links
    expect(scenarios.size).to be > 50

    expect(scenarios.filter_map { render_failure("#{it}/preview") }).to be_empty
  end

  it "renders a preview under every installed theme" do
    failures = PlaceCal::Extensions.theme_names.filter_map do |theme|
      render_failure("#{preview_path('sites/event')}/list_view/preview?_display=#{CGI.escape({ theme: }.to_json)}")
    end

    expect(failures).to be_empty
  end

  it "keeps directory previews off local-site themes" do
    get "#{preview_path('directory/footer')}/default/preview?_display=#{CGI.escape({ theme: 'transdimension' }.to_json)}"
    expect(response).to be_successful
    expect(response.body).not_to include("transdimension/theme")

    get "#{preview_path('sites/event')}/list_view/preview?_display=#{CGI.escape({ theme: 'transdimension' }.to_json)}"
    expect(response.body).to include("transdimension/theme")
  end

  it "shows every scenario on a component's own page" do
    get preview_path("sites/event")
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
