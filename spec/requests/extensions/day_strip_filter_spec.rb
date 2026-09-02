# frozen_string_literal: true

require "rails_helper"

# WP 1.3b (#3368, D22): a site whose theme sets `event_filter_style :day_strip`
# gets the Today / Tomorrow / next five days strip in place of the date picker.
RSpec.describe "Day strip event filter", type: :request do
  let(:ward) { create(:riverside_ward) }

  before do
    site.neighbourhoods << ward
  end

  context "with a theme that asks for the day strip" do
    let(:site) do
      create(:site, slug: "exampled", theme: "example_theme", url: "https://exampled.lvh.me")
    end

    it "renders the day strip instead of the date picker" do
      get "http://exampled.lvh.me/events"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("day-strip")
      expect(response.body).to include("All upcoming")
      expect(response.body).to include("Tomorrow")
      expect(response.body).not_to include("Go to date")
    end

    it "links days to the existing dated event URLs" do
      get "http://exampled.lvh.me/events"

      today = Time.zone.today
      expect(response.body).to include("/events/#{today.year}/#{today.month}/#{today.day}?period=day#paginator")
      expect(response.body).to include("/events?period=future#paginator")
    end
  end

  context "with a core theme" do
    let(:site) do
      create(:site, slug: "corely", theme: "pink", url: "https://corely.lvh.me")
    end

    it "keeps the date picker" do
      get "http://corely.lvh.me/events"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Go to date")
      expect(response.body).not_to include("day-strip")
    end
  end
end
