# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Open Graph images", type: :request do
  let(:site) { create(:site, slug: "test-site") }

  describe "GET /events/:id/opengraph.png" do
    it "returns a PNG" do
      event = create(:event)
      get event_og_image_url(event, host: "lvh.me")

      expect(response).to be_successful
      expect(response.content_type).to eq("image/png")
    end

    it "404s for a missing event" do
      get event_og_image_url(id: "missing", host: "lvh.me")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /partners/:id/opengraph.png" do
    it "returns a PNG" do
      partner = create(:partner)
      get partner_og_image_url(partner, host: "lvh.me")

      expect(response).to be_successful
      expect(response.content_type).to eq("image/png")
    end

    it "404s for a hidden partner" do
      partner = create(:partner)
      partner.update_columns(hidden: true) # rubocop:disable Rails/SkipsModelValidations
      get partner_og_image_url(partner, host: "lvh.me")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /partnerships/:id/opengraph.png" do
    it "returns a PNG" do
      site.update!(is_published: true)
      get partnership_og_image_url(site, host: "lvh.me")

      expect(response).to be_successful
      expect(response.content_type).to eq("image/png")
    end
  end

  describe "GET /opengraph.png" do
    it "returns the site card on a site subdomain" do
      get og_image_url(host: "#{site.slug}.lvh.me")

      expect(response).to be_successful
      expect(response.content_type).to eq("image/png")
    end

    it "returns the generic brand card on the main domain" do
      get og_image_url(host: "lvh.me")

      expect(response).to be_successful
      expect(response.content_type).to eq("image/png")
    end
  end

  describe "og:image meta tags" do
    it "points event pages at the event card" do
      event = create(:event)
      get event_url(event, host: "lvh.me")

      expect(response.body).to include("/events/#{event.id}/opengraph.png")
    end

    it "points partner pages at the partner card" do
      partner = create(:partner)
      get partner_url(partner, host: "lvh.me")

      expect(response.body).to include("/partners/#{partner.slug}/opengraph.png")
    end

    it "does not include an og:image on Devise pages" do
      get new_user_session_url(host: "lvh.me")

      expect(response).to be_successful
      expect(response.body).not_to include("og:image")
    end
  end
end
