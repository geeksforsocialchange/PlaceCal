# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Robots", type: :request do
  let!(:published_site) { create(:site, is_published: true) }
  let!(:unpublished_site) { create(:site, is_published: false) }

  describe "GET /robots.txt" do
    context "for unpublished site" do
      it "blocks crawlers with blanket disallow" do
        get "http://#{unpublished_site.slug}.lvh.me/robots.txt"
        expect(response).to be_successful
        expect(response.body).to include("User-agent: *\nDisallow: /")
      end
    end

    context "for published site" do
      it "allows general crawlers" do
        get "http://#{published_site.slug}.lvh.me/robots.txt"
        expect(response).to be_successful
        expect(response.body).to include("robotstxt.org")
        # Should not have a blanket disallow for all user agents
        expect(response.body).not_to match(%r{^User-agent: \*\nDisallow: /$})
      end
    end
  end
end
