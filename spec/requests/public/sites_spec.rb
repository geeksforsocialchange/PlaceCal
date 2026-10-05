# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Sites", type: :request do
  let(:site_admin) { create(:root_user) }
  let(:site) { create(:site, slug: "hulme", site_admin: site_admin, url: "https://hulme.lvh.me", place_name: "Hulme Community") }
  let(:ward) { create(:riverside_ward) }

  before do
    site.neighbourhoods << ward
  end

  describe "subdomain routing" do
    it "shows the directory for the base domain" do
      get "http://lvh.me"
      expect(response).to be_successful
    end

    it "redirects non-existent site slug to the apex" do
      get "http://no-site-set.lvh.me"
      expect(response).to redirect_to("http://lvh.me/")
    end

    it "shows site page for valid subdomain" do
      get "http://hulme.lvh.me"
      expect(response).to be_successful
    end
  end

  describe "site page content" do
    it "shows site description" do
      get "http://hulme.lvh.me"
      expect(response).to be_successful
      expect(response.body).to include(site.description)
    end

    it "shows site admin contact info" do
      get "http://hulme.lvh.me"
      expect(response).to be_successful
      expect(response.body).to include(site_admin.email)
    end
  end

  describe "find placecal page" do
    it "shows published sites" do
      # Publish the site so it appears in the list
      site.update!(is_published: true)

      get find_placecal_url(host: "lvh.me")
      expect(response).to be_successful
      expect(response.body).to include(site.place_name)
    end
  end

  describe "tag cards" do
    it "hides tag cards by default" do
      get "http://hulme.lvh.me"
      expect(response.body).not_to include("help__computer_access")
      expect(response.body).not_to include("help__free_public_wifi")
    end

    context "with computer access tag" do
      let!(:computers_tag) { create(:tag, name: "computers") }
      let!(:partner) { create(:partner, address: create(:address, neighbourhood: ward)) }

      before do
        site.tags << computers_tag
        partner.tags << computers_tag
        partner.service_area_neighbourhoods << ward
      end

      it "shows computer access card when partners have tag" do
        get "http://hulme.lvh.me"
        expect(response.body).to include("help__computer_access")
      end
    end

    context "with wifi tag" do
      let!(:wifi_tag) { create(:tag, name: "wifi") }
      let!(:partner) { create(:partner, address: create(:address, neighbourhood: ward)) }

      before do
        site.tags << wifi_tag
        partner.tags << wifi_tag
        partner.service_area_neighbourhoods << ward
      end

      it "shows wifi card when partners have tag" do
        get "http://hulme.lvh.me"
        expect(response.body).to include("help__free_public_wifi")
      end
    end
  end

  describe "custom hero text" do
    let!(:hero_site) { create(:site, hero_text: "Custom Hero Text", slug: "hero", site_admin: site_admin) }

    it "shows custom hero text when set" do
      get "http://hero.lvh.me"
      expect(response).to be_successful
      expect(response.body).to include("Custom Hero Text")
    end
  end

  describe "region filter" do
    let(:region_site) { create(:site, slug: "regions", place_name: "Regionshire") }
    let(:region_ward) { create(:riverside_ward) }
    let(:north_tag) { create(:partnership, name: "North") }
    let(:south_tag) { create(:partnership, name: "South") }

    before do
      region_site.neighbourhoods << region_ward
      region_site.tags << north_tag
    end

    context "when the site has one partnership tag" do
      it "does not show the region control on the homepage" do
        get "http://regions.lvh.me"

        expect(response).to be_successful
        expect(response.body).not_to include("region-filter")
      end
    end

    context "when the site has two partnership tags" do
      before { region_site.tags << south_tag }

      it "shows the region control on the homepage" do
        get "http://regions.lvh.me"

        expect(response.body).to include("region-filter")
        expect(response.body).to include("South")
      end

      it "ignores an unknown region slug" do
        get "http://regions.lvh.me?region=nowhere"

        expect(response).to be_successful
        expect(response.body).to include("region-filter")
      end

      # The control is only worth having if the lists below it obey it (D7).
      context "when the homepage help cards list partners" do
        let(:computers) { create(:tag, name: "Computers", slug: "computers", type: "Facility") }

        def partner_in(region_tag, name)
          partner = create(:partner, name: name, address: create(:address, neighbourhood: region_ward))
          partner.tags << [region_tag, computers]
          partner
        end

        before do
          partner_in(north_tag, "Northern Library")
          partner_in(south_tag, "Southern Library")
        end

        it "lists every region's partners with no region selected" do
          get "http://regions.lvh.me"

          expect(response.body).to include("Northern Library")
          expect(response.body).to include("Southern Library")
        end

        it "lists only the selected region's partners" do
          get "http://regions.lvh.me?region=#{north_tag.slug}"

          expect(response.body).to include("Northern Library")
          expect(response.body).not_to include("Southern Library")
        end

        it "ignores an unknown region slug and lists everything" do
          get "http://regions.lvh.me?region=nowhere"

          expect(response.body).to include("Northern Library")
          expect(response.body).to include("Southern Library")
        end
      end

      it "carries the region on the site navigation links" do
        get "http://regions.lvh.me?region=#{north_tag.slug}"

        expect(response.body).to include(%(href="/events?region=#{north_tag.slug}"))
        expect(response.body).to include(%(href="/partners?region=#{north_tag.slug}"))
      end
    end
  end
end
