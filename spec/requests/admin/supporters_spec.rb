# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Supporters", type: :request do
  describe "GET /admin/supporters" do
    context "as an unauthenticated user" do
      it "redirects to login" do
        get admin_supporters_url(host: admin_host)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a root user" do
      let(:user) { create(:root_user) }
      let!(:supporter) { create(:supporter) }

      before { sign_in user }

      it "shows supporters index" do
        get admin_supporters_url(host: admin_host)
        expect(response).to be_successful
      end
    end
  end

  describe "GET /admin/supporters/new" do
    let(:user) { create(:root_user) }

    before { sign_in user }

    it "shows the new supporter form" do
      get new_admin_supporter_url(host: admin_host)
      expect(response).to be_successful
    end
  end

  describe "GET /admin/supporters/:id/edit" do
    let(:user) { create(:root_user) }
    let(:supporter) { create(:supporter) }

    before { sign_in user }

    it "shows the edit form" do
      get edit_admin_supporter_url(supporter, host: admin_host)
      expect(response).to be_successful
      expect(response.body).to include(supporter.name)
    end
  end

  describe "POST /admin/supporters" do
    let(:user) { create(:root_user) }

    before { sign_in user }

    context "with valid params" do
      it "creates a supporter and redirects" do
        post admin_supporters_url(host: admin_host), params: {
          supporter: { name: "New Supporter", url: "https://example.com", description: "A test" }
        }
        expect(response).to be_redirect
      end
    end
  end

  describe "DELETE /admin/supporters/:id" do
    let(:user) { create(:root_user) }
    let!(:supporter) { create(:supporter) }

    before { sign_in user }

    it "deletes the supporter" do
      expect do
        delete admin_supporter_url(supporter, host: admin_host)
      end.to change(Supporter, :count).by(-1)
      expect(response).to be_redirect
    end
  end
end
