# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Robots", type: :request do
  let!(:published_site) { create(:site, is_published: true) }
  let!(:unpublished_site) { create(:site, is_published: false) }

  describe "GET /robots.txt" do
    context "for unpublished site" do
      it "blocks crawlers" do
        get "http://#{unpublished_site.slug}.lvh.me/robots.txt"
        expect(response).to be_successful
        expect(response.body).to include("Disallow: /")
      end
    end

    context "for published site" do
      it "allows crawlers" do
        get "http://#{published_site.slug}.lvh.me/robots.txt"
        expect(response).to be_successful
        expect(response.body).to include("robotstxt.org")
        expect(response.body).not_to include("Disallow: /")
      end
    end
  end
end
