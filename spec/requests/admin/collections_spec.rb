# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Collections", type: :request do
  describe "GET /admin/collections" do
    context "as an unauthenticated user" do
      it "redirects to login" do
        get admin_collections_url(host: admin_host)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a root user" do
      let(:user) { create(:root_user) }
      let!(:collection) { create(:collection) }

      before { sign_in user }

      it "shows collections index" do
        get admin_collections_url(host: admin_host)
        expect(response).to be_successful
      end
    end
  end

  describe "GET /admin/collections/new" do
    let(:user) { create(:root_user) }

    before { sign_in user }

    it "shows the new collection form" do
      get new_admin_collection_url(host: admin_host)
      expect(response).to be_successful
    end
  end

  describe "GET /admin/collections/:id/edit" do
    let(:user) { create(:root_user) }
    let(:collection) { create(:collection) }

    before { sign_in user }

    it "shows the edit form" do
      get edit_admin_collection_url(collection, host: admin_host)
      expect(response).to be_successful
      expect(response.body).to include(collection.name)
    end
  end

  describe "POST /admin/collections" do
    let(:user) { create(:root_user) }

    before { sign_in user }

    context "with valid params" do
      it "creates a collection and redirects" do
        post admin_collections_url(host: admin_host), params: {
          collection: { name: "New Collection", description: "A test collection" }
        }
        expect(response).to be_redirect
      end
    end

    context "with valid params and redirect" do
      it "creates a collection successfully" do
        post admin_collections_url(host: admin_host), params: {
          collection: { name: "Another Collection", description: "Test" }
        }
        expect(response).to be_redirect
      end
    end
  end

  describe "DELETE /admin/collections/:id" do
    let(:user) { create(:root_user) }
    let!(:collection) { create(:collection) }

    before { sign_in user }

    it "deletes the collection" do
      expect do
        delete admin_collection_url(collection, host: admin_host)
      end.to change(Collection, :count).by(-1)
      expect(response).to be_redirect
    end
  end
end
