# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin background jobs", type: :request do
  describe "the jobs page" do
    it "sends a signed-out visitor to sign in" do
      get admin_jobs_url(host: admin_host)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "turns away a user who isn't root" do
      sign_in create(:citizen_user)
      get admin_jobs_url(host: admin_host)
      expect(response).to redirect_to(admin_root_path)
    end

    it "shows a root user Mission Control inside the admin layout" do
      sign_in create(:root_user)
      get admin_jobs_url(host: admin_host)

      frame = Nokogiri::HTML(response.body).at_css("iframe")
      expect(frame["src"]).to eq("/jobs/dashboard")
      expect(frame["title"]).to eq(I18n.t("admin.jobs.title"))
      expect(response.body).to include(I18n.t("admin.leftbar.jobs"))
    end
  end

  describe "Mission Control itself" do
    it "turns away a user who isn't root" do
      sign_in create(:citizen_user)
      get "#{admin_jobs_url(host: admin_host)}/dashboard"
      expect(response).to be_redirect
    end

    it "shows a root user the queues, without a link out of the frame" do
      sign_in create(:root_user)
      get "#{admin_jobs_url(host: admin_host)}/dashboard"
      follow_redirect! while response.redirect?

      expect(response).to be_successful
      expect(response.body).to include("Queues")
      expect(response.body).not_to include("Back to main app")
    end
  end
end
