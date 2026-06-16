# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Directory Partners", type: :request do
  let(:ward) { create(:riverside_ward) }

  describe "GET /partners (directory index)" do
    let!(:partner) do
      create(:partner,
             address: create(:address, neighbourhood: ward),
             summary: "A community group doing great things")
    end

    it "returns successful response" do
      get partners_url(host: "lvh.me")
      expect(response).to be_successful
    end

    it "displays partner names" do
      get partners_url(host: "lvh.me")
      expect(response.body).to include(partner.name)
    end

    it "displays partner summary" do
      get partners_url(host: "lvh.me")
      expect(response.body).to include("A community group doing great things")
    end

    it "displays neighbourhood trail" do
      get partners_url(host: "lvh.me")
      trail = ward.hierarchy_path.last(3).map(&:shortname)
      trail.each do |segment|
        expect(response.body).to include(segment)
      end
    end

    it "displays category chips" do
      category = create(:category_tag)
      partner.categories << category
      get partners_url(host: "lvh.me")
      expect(response.body).to include(category.name)
    end

    it "sets page title" do
      get partners_url(host: "lvh.me")
      expect(response.body).to include("<title>Partners | PlaceCal</title>")
    end

    context "with A-Z sort" do
      it "returns successful response" do
        get partners_url(host: "lvh.me", params: { sort: "name" })
        expect(response).to be_successful
      end

      it "shows A-Z jump bar" do
        get partners_url(host: "lvh.me", params: { sort: "name" })
        letter = partner.name[0].upcase
        expect(response.body).to include("letter-#{letter}")
      end

      # Regression for #3226: the neighbourhood filter adds DISTINCT, and the
      # A-Z letter pluck must not carry the name ORDER BY into the DISTINCT
      # select or Postgres raises PG::InvalidColumnReference.
      it "succeeds when combined with a neighbourhood filter" do
        get partners_url(host: "lvh.me", params: { sort: "name", neighbourhood: ward.id })
        expect(response).to be_successful
      end
    end

    context "with service-area-only partner" do
      let!(:sa_partner) do
        create(:mobile_partner, service_area_wards: [ward])
      end

      it "displays service area neighbourhood trail" do
        get partners_url(host: "lvh.me")
        expect(response.body).to include(sa_partner.name)
        trail = ward.hierarchy_path.last(3).map(&:shortname)
        trail.each do |segment|
          expect(response.body).to include(segment)
        end
      end
    end

    context "with filters" do
      let(:category) { create(:category_tag) }

      before { partner.categories << category }

      it "filters by category" do
        get partners_url(host: "lvh.me", params: { category: category.id })
        expect(response).to be_successful
      end

      it "filters by search query" do
        get partners_url(host: "lvh.me", params: { q: partner.name })
        expect(response).to be_successful
        expect(response.body).to include(partner.name)
      end
    end

    context "with cross-filtering facets" do
      let(:other_ward) { create(:oldtown_ward) }
      let!(:alpha_partner) do
        create(:partner, address: create(:address, neighbourhood: ward))
          .tap { |p| p.categories << create(:category_tag, name: "Alphacat") }
      end
      let!(:bravo_partner) do
        create(:partner, address: create(:address, neighbourhood: other_ward))
          .tap { |p| p.categories << create(:category_tag, name: "Bravocat") }
      end

      it "lists every category when unfiltered" do
        get partners_url(host: "lvh.me")
        expect(response.body).to include("Alphacat")
        expect(response.body).to include("Bravocat")
      end

      it "limits the category facet to the selected neighbourhood" do
        get partners_url(host: "lvh.me", params: { neighbourhood: ward.id })
        expect(response.body).to include("Alphacat")
        expect(response.body).not_to include("Bravocat")
      end

      it "still shows the selected neighbourhood when no partners match the other filters" do
        # other_ward has no Alphacat partners, but the picker should reflect it.
        get partners_url(host: "lvh.me", params: { neighbourhood: other_ward.id, category: alpha_partner.categories.first.id })
        expect(response.body).to include(other_ward.shortname)
      end
    end
  end

  describe "GET /partners/:id (directory show)" do
    let(:partner) { create(:riverside_partner) }

    it "returns successful response" do
      get partner_url(partner, host: "lvh.me")
      expect(response).to be_successful
    end

    it "displays partner name in hero" do
      get partner_url(partner, host: "lvh.me")
      expect(response.body).to include(partner.name)
    end

    it "shows breadcrumb navigation" do
      get partner_url(partner, host: "lvh.me")
      expect(response.body).to include(I18n.t("directory.breadcrumbs.root"))
    end

    it "shows contact details when present" do
      get partner_url(partner, host: "lvh.me")
      expect(response.body).to include(I18n.t("directory.contact.get_in_touch"))
      expect(response.body).to include(partner.public_email)
    end

    it "hides contact card when no contact info" do
      bare = create(:partner,
                    address: create(:address, neighbourhood: ward),
                    public_email: nil, public_phone: nil, url: nil,
                    twitter_handle: nil, facebook_link: nil, instagram_handle: nil)
      get partner_url(bare, host: "lvh.me")
      expect(response.body).not_to include("tel:0161")
    end

    it "shows categories in sidebar" do
      category = create(:category_tag)
      partner.categories << category
      get partner_url(partner, host: "lvh.me")
      expect(response.body).to include(category.name)
    end

    it "shows neighbourhood in sidebar" do
      get partner_url(partner, host: "lvh.me")
      expect(response.body).to include(partner.address.neighbourhood.name)
    end

    context "with accessibility info" do
      before { partner.update!(accessibility_info: "Wheelchair accessible entrance") }

      it "shows accessibility section" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include(I18n.t("directory.partners.show.accessibility_info"))
        expect(response.body).to include("Wheelchair accessible entrance")
      end
    end

    context "without accessibility info" do
      it "hides accessibility section" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).not_to include(I18n.t("directory.partners.show.accessibility_info"))
      end
    end

    context "with events" do
      let(:calendar) { create(:calendar, organiser: partner) }

      before do
        12.times do |i|
          create(:event,
                 dtstart: (i + 1).days.from_now,
                 calendar: calendar,
                 organiser: partner)
        end
      end

      it "shows upcoming events heading" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include(I18n.t("directory.partners.show.upcoming_events"))
      end

      it "shows overflow prompt for events beyond first 10" do
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include("Show 2 more events")
      end

      it "pluralizes correctly for single remaining event" do
        Event.last.destroy!
        get partner_url(partner, host: "lvh.me")
        expect(response.body).to include("Show 1 more event")
        expect(response.body).not_to include("Show 1 more events")
      end
    end

    context "with service areas" do
      let(:sa_partner) { create(:mobile_partner, service_area_wards: [ward]) }

      it "shows service area in location section" do
        get partner_url(sa_partner, host: "lvh.me")
        expect(response.body).to include(I18n.t("directory.partners.show.location"))
      end
    end
  end
end
