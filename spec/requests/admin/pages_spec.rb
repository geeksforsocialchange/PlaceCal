# frozen_string_literal: true

require "rails_helper"

# WP 1.1 (#3368, D5): admin CRUD for a Site's static content pages.
RSpec.describe "Admin::Pages", type: :request do
  let!(:root_user) { create(:root_user) }
  let!(:citizen_user) { create(:citizen_user) }
  let(:site_admin_user) { create(:user) }
  let!(:site) { create(:site, name: "Hulme", site_admin: site_admin_user) }
  let!(:other_site) { create(:site, name: "Other") }
  let!(:page_record) { create(:page, site: site, slug: "about", title: "About Hulme") }
  let!(:other_page) { create(:page, site: other_site, slug: "about", title: "About Other") }

  describe "GET /admin/pages" do
    context "as a root user" do
      before { sign_in root_user }

      it "lists every page" do
        get admin_pages_url(host: admin_host)

        expect(response).to be_successful
        expect(response.body).to include("About Hulme")
        expect(response.body).to include("About Other")
      end
    end

    context "as a site admin" do
      before { sign_in site_admin_user }

      it "lists only their own site's pages" do
        get admin_pages_url(host: admin_host)

        expect(response).to be_successful
        expect(response.body).to include("About Hulme")
        expect(response.body).not_to include("About Other")
      end
    end

    context "as a citizen" do
      before { sign_in citizen_user }

      it "is not authorised" do
        get admin_pages_url(host: admin_host)

        expect(response).to redirect_to(admin_root_path)
      end
    end
  end

  describe "GET /admin/pages/new" do
    context "as a root user" do
      before { sign_in root_user }

      it "offers a site selector" do
        get new_admin_page_url(host: admin_host)

        expect(response).to be_successful
        expect(response.body).to include("Hulme")
        expect(response.body).to include("Other")
      end
    end

    context "as a site admin" do
      before { sign_in site_admin_user }

      it "renders the form" do
        get new_admin_page_url(host: admin_host)

        expect(response).to be_successful
      end

      it "does not offer another site" do
        get new_admin_page_url(host: admin_host)

        expect(response.body).not_to include("Other")
      end
    end
  end

  describe "POST /admin/pages" do
    context "as a site admin" do
      before { sign_in site_admin_user }

      it "creates a page on their own site" do
        expect do
          post admin_pages_url(host: admin_host),
               params: { page: { title: "Our story", slug: "our-history", body: "Hello" } }
        end.to change(Page, :count).by(1)

        expect(Page.last.site).to eq(site)
        expect(Page.last.body_html).to include("Hello")
      end

      it "cannot assign the page to another site" do
        post admin_pages_url(host: admin_host),
             params: { page: { title: "Our story", slug: "our-history", body: "Hello", site_id: other_site.id } }

        expect(Page.last.site).to eq(site)
      end

      it "rejects a reserved slug" do
        expect do
          post admin_pages_url(host: admin_host),
               params: { page: { title: "Events", slug: "events", body: "Hello" } }
        end.not_to change(Page, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("reserved by PlaceCal")
      end
    end

    context "as a root user" do
      before { sign_in root_user }

      it "can assign any site" do
        post admin_pages_url(host: admin_host),
             params: { page: { title: "Our story", slug: "our-history", body: "Hello", site_id: other_site.id } }

        expect(Page.last.site).to eq(other_site)
      end
    end
  end

  describe "PATCH /admin/pages/:id" do
    context "as the site's admin" do
      before { sign_in site_admin_user }

      it "updates their own page" do
        patch admin_page_url(page_record, host: admin_host),
              params: { page: { title: "About us", slug: "about", body: "Updated" } }

        expect(response).to redirect_to(edit_admin_page_path(page_record))
        expect(page_record.reload.title).to eq("About us")
      end

      it "cannot update another site's page" do
        patch admin_page_url(other_page, host: admin_host),
              params: { page: { title: "Hacked" } }

        expect(response).to redirect_to(admin_root_path)
        expect(other_page.reload.title).to eq("About Other")
      end
    end
  end

  describe "DELETE /admin/pages/:id" do
    context "as the site's admin" do
      before { sign_in site_admin_user }

      it "deletes their own page" do
        expect do
          delete admin_page_url(page_record, host: admin_host)
        end.to change(Page, :count).by(-1)
      end

      it "cannot delete another site's page" do
        expect do
          delete admin_page_url(other_page, host: admin_host)
        end.not_to change(Page, :count)
      end
    end
  end
end
