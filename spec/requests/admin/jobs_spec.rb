# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin job dashboard (Mission Control Jobs)", type: :request do
  describe "GET /jobs" do
    context "as an unauthenticated user" do
      it "redirects to login" do
        get admin_jobs_url(host: admin_host)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as a non-root user" do
      let(:user) { create(:citizen_user) }

      before { sign_in user }

      it "redirects away" do
        get admin_jobs_url(host: admin_host)
        expect(response).to be_redirect
      end
    end

    context "as a root user" do
      let(:user) { create(:root_user) }

      before { sign_in user }

      it "shows Mission Control's job dashboard" do
        get admin_jobs_url(host: admin_host)
        follow_redirect! while response.redirect?

        expect(response).to be_successful
        expect(response.body).to include("Queues")
      end
    end
  end
end
