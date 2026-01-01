# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Sites", type: :request do
  let!(:default_site) { create_default_site }
  let(:site_admin) { create(:root_user) }
  let(:site) { create(:site, slug: "hulme", site_admin: site_admin, url: "https://hulme.lvh.me", place_name: "Hulme Community") }
  let(:ward) { create(:riverside_ward) }

  before do
    site.neighbourhoods << ward
  end

  describe "subdomain routing" do
    it "shows default site for base domain" do
      get "http://lvh.me"
      expect(response).to be_successful
    end

    it "redirects non-existent site slug to default" do
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
end
