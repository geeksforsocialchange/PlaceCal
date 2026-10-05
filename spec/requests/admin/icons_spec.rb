# frozen_string_literal: true

require "rails_helper"

# The admin icon gallery (Admin::PagesController#icons) is a root-only
# developer reference, so its authorisation is worth holding onto.
RSpec.describe "Admin::Icons", type: :request do
  describe "GET /admin/icons" do
    context "as an unauthenticated user" do
      it "redirects to login" do
        get admin_icons_url(host: admin_host)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a non-root user" do
      let(:user) { create(:citizen_user) }

      before { sign_in user }

      it "redirects away" do
        get admin_icons_url(host: admin_host)
        expect(response).to be_redirect
      end
    end

    context "as a root user" do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it "shows the icons page" do
        get admin_icons_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include("icon")
      end
    end
  end
end
