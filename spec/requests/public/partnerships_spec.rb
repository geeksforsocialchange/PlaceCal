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

    it "shows each partnership's place name on its card" do
      partnerships.first.update!(place_name: "Hulme")
      get partnerships_url(host: "lvh.me")
      expect(response.body).to include("Hulme")
    end

    it "leaves the area out of a card when the place name is blank" do
      partnerships.first.sites_neighbourhoods.create!(neighbourhood: create(:neighbourhood, name: "Primaryshire"), relation_type: "Primary")
      get partnerships_url(host: "lvh.me")
      expect(response.body).not_to include("Primaryshire")
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
      expect(response.body).to include(%(href="https://#{partnership.slug}.placecal.org"))
    end

    it "sends the visit button to an external domain but keeps PlaceCal's pages for see-all links" do
      partnership.update!(domain: "fruitsaladevents.co.uk")
      get partnership_url(partnership, host: "lvh.me")
      expect(response.body).to include('href="https://fruitsaladevents.co.uk"')
      expect(response.body).to include(%(href="https://#{partnership.slug}.placecal.org/partners"))
      expect(response.body).not_to include("https://fruitsaladevents.co.uk/partners")
    end

    it "shows get involved card" do
      get partnership_url(partnership, host: "lvh.me")
      expect(response.body).to include(I18n.t("directory.partnerships.show.get_involved"))
      expect(response.body).to include(I18n.t("directory.partnerships.show.contact_coordinator"))
    end

    context "with a place name" do
      before { partnership.update!(place_name: "Hulme") }

      it "names the area in the stat chips and the get involved card" do
        get partnership_url(partnership, host: "lvh.me")
        page = Capybara.string(response.body)
        expect(page).to have_text("Hulme", minimum: 2)
        expect(response.body).to include(I18n.t("directory.partnerships.show.cta_text", area: I18n.t("directory.partnerships.show.cta_area", name: "Hulme")))
      end
    end

    context "with a blank place name" do
      before do
        partnership.sites_neighbourhoods.create!(neighbourhood: create(:neighbourhood, name: "Primaryshire"), relation_type: "Primary")
      end

      it "leaves the area out rather than naming the primary neighbourhood" do
        get partnership_url(partnership, host: "lvh.me")
        expect(response.body).not_to include("Primaryshire")
        expect(response.body).to include(I18n.t("directory.partnerships.show.cta_text", area: ""))
      end
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
                 calendar:,
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
