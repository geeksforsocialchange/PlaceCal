# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Partnerships", type: :request do
  describe "GET /admin/partnerships" do
    context "as an unauthenticated user" do
      it "redirects to login" do
        get admin_partnerships_url(host: admin_host)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a root user" do
      let(:user) { create(:root_user) }
      let!(:partnership) { create(:partnership) }

      before { sign_in user }

      it "shows partnerships index" do
        get admin_partnerships_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("Partnership")
      end
    end
  end

  describe "GET /admin/partnerships/new" do
    context "as a root user" do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it "shows the new partnership form" do
        get new_admin_partnership_url(host: admin_host)
        expect(response).to be_successful
      end
    end
  end

  describe "GET /admin/partnerships/:id/edit" do
    let(:user) { create(:root_user) }
    let(:partnership) { create(:partnership) }

    before { sign_in user }

    it "shows the edit form" do
      get edit_admin_partnership_url(partnership, host: admin_host)
      expect(response).to be_successful
      expect(response.body).to include(partnership.name)
    end
  end

  describe "POST /admin/partnerships" do
    let(:user) { create(:root_user) }

    before { sign_in user }

    context "with valid params" do
      it "creates a partnership and redirects" do
        post admin_partnerships_url(host: admin_host), params: {
          partnership: { name: "New Partnership" }
        }
        expect(response).to be_redirect
      end
    end

    context "with invalid params" do
      it "re-renders the form" do
        post admin_partnerships_url(host: admin_host), params: {
          partnership: { name: "" }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PUT /admin/partnerships/:id" do
    let(:user) { create(:root_user) }
    let(:partnership) { create(:partnership) }

    before { sign_in user }

    it "updates the partnership" do
      put admin_partnership_url(partnership, host: admin_host), params: {
        partnership: { name: "Updated Name" }
      }
      expect(response).to be_redirect
    end
  end

  describe "DELETE /admin/partnerships/:id" do
    let(:user) { create(:root_user) }
    let!(:partnership) { create(:partnership) }

    before { sign_in user }

    it "deletes the partnership" do
      expect do
        delete admin_partnership_url(partnership, host: admin_host)
      end.to change(Partnership, :count).by(-1)
      expect(response).to be_redirect
    end
  end
end
