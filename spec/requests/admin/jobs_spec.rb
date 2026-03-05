# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Jobs", type: :request do
  describe "GET /admin/jobs" do
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

      it "shows the jobs page" do
        get admin_jobs_url(host: admin_host)
        expect(response).to be_successful
      end
    end
  end
end
