# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Partnerships", type: :request do
  let!(:directory_site) { create_directory_site }

  describe "on directory site" do
    let(:host) { "directory.lvh.me" }

    context "GET /partnerships" do
      let!(:partnership) { create(:partnership, name: "Test Partnership") }
      let!(:partner) { create(:partner, hidden: false) }

      before do
        partner.tags << partnership
      end

      it "returns success" do
        get partnerships_url(host: host)
        expect(response).to be_successful
      end

      it "shows partnerships with visible partners" do
        get partnerships_url(host: host)
        expect(response.body).to include("Test Partnership")
      end
    end

    context "GET /partnerships/:id" do
      let!(:partnership) { create(:partnership, name: "Test Partnership") }
      let!(:partner) { create(:partner, hidden: false, name: "Test Partner") }

      before do
        partner.tags << partnership
      end

      it "returns success" do
        get partnership_url(partnership, host: host)
        expect(response).to be_successful
      end

      it "shows the partnership name" do
        get partnership_url(partnership, host: host)
        expect(response.body).to include("Test Partnership")
      end

      it "shows the partner" do
        get partnership_url(partnership, host: host)
        expect(response.body).to include("Test Partner")
      end
    end
  end

  describe "on non-directory site" do
    let!(:default_site) { create_default_site }

    it "redirects partnerships page on base domain" do
      get partnerships_url(host: "lvh.me")
      expect(response).to be_redirect
    end
  end

  describe "on subsite" do
    let!(:site) { create(:millbrook_site) }

    it "redirects partnerships page on subsite" do
      get partnerships_url(host: "#{site.slug}.lvh.me")
      expect(response).to be_redirect
    end
  end
end
