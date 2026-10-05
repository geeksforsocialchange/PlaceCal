# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Partnerships", type: :request do
  let!(:partnerships) do
    Array.new(3) do |i|
      create(:site, slug: "partnership-#{i}", is_published: true, name: "Test Partnership #{i}")
    end
  end

  describe "GET /partnerships (directory)" do
    it "returns successful response" do
      get partnerships_url(host: "lvh.me")
      expect(response).to be_successful
    end

    it "displays partnership names" do
      get partnerships_url(host: "lvh.me")
      partnerships.each do |partnership|
        expect(response.body).to include(partnership.name)
      end
    end

    it "sets page title" do
      get partnerships_url(host: "lvh.me")
      expect(response.body).to include("<title>#{Partnership.model_name.human(count: 2)}")
    end

    it "shows hero with i18n title" do
      get partnerships_url(host: "lvh.me")
      expect(response.body).to include(I18n.t("directory.partnerships.index.hero_title"))
    end

    context "with search query" do
      it "returns successful response" do
        get partnerships_url(host: "lvh.me", params: { q: partnerships.first.name })
        expect(response).to be_successful
      end
    end

    context "with no results" do
      it "shows empty state" do
        get partnerships_url(host: "lvh.me", params: { q: "nonexistent-xyz" })
        expect(response).to be_successful
        expect(response.body).to include(I18n.t("directory.partnerships.index.empty"))
      end
    end
  end

  describe "GET /partnerships/:id (directory)" do
    let(:partnership) { partnerships.first }

    it "returns successful response" do
      get partnership_url(partnership, host: "lvh.me")
      expect(response).to be_successful
    end

    it "displays partnership name" do
      get partnership_url(partnership, host: "lvh.me")
      expect(response.body).to include(partnership.name)
    end

    it "shows breadcrumb with i18n" do
      get partnership_url(partnership, host: "lvh.me")
      expect(response.body).to include(I18n.t("directory.breadcrumbs.root"))
      expect(response.body).to include(Partnership.model_name.human(count: 2))
    end

    it "shows visit button" do
      get partnership_url(partnership, host: "lvh.me")
      expect(response.body).to include("#{partnership.slug}.placecal.org")
    end

    it "shows get involved card" do
      get partnership_url(partnership, host: "lvh.me")
      expect(response.body).to include(I18n.t("directory.partnerships.show.get_involved"))
      expect(response.body).to include(I18n.t("directory.partnerships.show.contact_coordinator"))
    end

    context "with partners in neighbourhood" do
      let(:ward) { create(:riverside_ward) }

      before do
        partnership.neighbourhoods << ward
        3.times do
          create(:partner, address: create(:address, neighbourhood: ward))
        end
      end

      it "displays partner count" do
        get partnership_url(partnership, host: "lvh.me")
        expect(response.body).to include("3 #{Partner.model_name.human(count: 3).downcase}")
      end
    end

    context "with events" do
      let(:ward) { create(:riverside_ward) }
      let(:partner) { create(:partner, address: create(:address, neighbourhood: ward)) }
      let(:calendar) { create(:calendar, organiser: partner) }

      before do
        partnership.neighbourhoods << ward
        12.times do |i|
          create(:event,
                 dtstart: (i + 1).days.from_now,
                 calendar: calendar,
                 organiser: partner)
        end
      end

      it "shows upcoming events heading" do
        get partnership_url(partnership, host: "lvh.me")
        expect(response.body).to include(I18n.t("directory.partnerships.show.upcoming_events"))
      end

      it "shows overflow prompt for events beyond first 10" do
        get partnership_url(partnership, host: "lvh.me")
        expect(response.body).to include("Show 2 more events")
      end

      it "pluralizes correctly for single remaining event" do
        Event.last.destroy!
        get partnership_url(partnership, host: "lvh.me")
        expect(response.body).to include("Show 1 more event")
        expect(response.body).not_to include("Show 1 more events")
      end
    end
  end
end
