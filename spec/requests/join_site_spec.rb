# frozen_string_literal: true

require "rails_helper"

# The join marketing site (join.placecal.org, #3163) is constrained to the
# join subdomain and the config.x.join_site_enabled flag (on by default
# outside production), so it merges without changing the live site.
RSpec.describe "Join marketing site", type: :request do
  describe "when enabled (the default outside production)" do
    it "serves the homepage" do
      get "http://join.lvh.me/"
      expect(response).to be_successful
      expect(response.body).to include("Set up PlaceCal in your community.")
    end

    it "serves the audiences index" do
      get "http://join.lvh.me/who-its-for"
      expect(response).to be_successful
      expect(response.body).to include("Who PlaceCal is for.")
    end

    DemoRequest::AUDIENCES.each do |key|
      it "serves the #{key.humanize.downcase} audience page" do
        get "http://join.lvh.me/who-its-for/#{key.tr('_', '-')}"
        expect(response).to be_successful
        expect(response.body).to include(CGI.escapeHTML(I18n.t("join.audiences.#{key}.hero")))
      end
    end

    it "404s an unknown audience" do
      get "http://join.lvh.me/who-its-for/pigeon-fanciers"
      expect(response).to have_http_status(:not_found)
    end

    %w[/features /our-story /pricing /book-a-demo].each do |path|
      it "serves #{path}" do
        get "http://join.lvh.me#{path}"
        expect(response).to be_successful
      end
    end

    it "renders the join chrome, not the directory chrome" do
      get "http://join.lvh.me/"
      expect(response.body).to include("join.placecal.org")
      expect(response.body).to include("Book a demo")
    end
  end

  describe "POST /book-a-demo" do
    # invisible_captcha's timestamp/spinner checks are off in test
    # (config/initializers/invisible_captcha.rb) so this posts directly.
    def submit_demo(params)
      post "http://join.lvh.me/book-a-demo", params: { demo_request: params }
    end

    it "sends the enquiry and redirects home" do
      expect do
        submit_demo(name: "Test User", email: "test@example.com",
                    organisation: "Test Org", audience: "housing_providers",
                    message: "We would like a demo")
      end.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to redirect_to("http://join.lvh.me/")
      expect(ActionMailer::Base.deliveries.last.subject).to eq("New demo request")
    end

    it "re-renders the form when required fields are missing" do
      expect do
        submit_demo(name: "", email: "")
      end.not_to(change { ActionMailer::Base.deliveries.count })

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "when disabled (the production default until launch)" do
    around do |example|
      Rails.application.config.x.join_site_enabled = false
      example.run
    ensure
      Rails.application.config.x.join_site_enabled = true
    end

    it "redirects the join subdomain to the apex" do
      get "http://join.lvh.me/"
      expect(response).to redirect_to("http://lvh.me/")
    end

    it "redirects join paths to their apex equivalent" do
      get "http://join.lvh.me/pricing"
      expect(response).to redirect_to("http://lvh.me/pricing")
    end
  end

  describe "the apex" do
    it "is unaffected by the join site" do
      get "http://lvh.me/"
      expect(response).to be_successful
    end
  end
end
