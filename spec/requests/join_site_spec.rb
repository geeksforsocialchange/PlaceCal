# frozen_string_literal: true

require "rails_helper"

# The join marketing site (join.placecal.org, #3163), served entirely from
# the join subdomain — unknown paths there bounce to the apex.
RSpec.describe "Join marketing site", type: :request do
  describe "the join subdomain" do
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

    Components::Join::Base::AUDIENCES.each do |key|
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

    it "reuses the directory Our Story page with a join breadcrumb and book-a-demo CTA" do
      get "http://join.lvh.me/our-story"
      expect(response.body).to include(CGI.escapeHTML(I18n.t("directory.pages.our_story.hero_title")))
      expect(response.body).to include(I18n.t("join.breadcrumbs.root"))
      expect(response.body).to include("/book-a-demo")
    end
  end

  describe "POST /book-a-demo" do
    # invisible_captcha's timestamp/spinner checks are off in test
    # (config/initializers/invisible_captcha.rb) so this posts directly.
    def submit_demo(params)
      post "http://join.lvh.me/book-a-demo", params: { contact_request: params }
    end

    it "sends the enquiry and redirects home" do
      expect do
        submit_demo(name: "Test User", email: "test@example.com",
                    job_org: "Test Org", why: "We would like a demo")
      end.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to redirect_to("http://join.lvh.me/")
      expect(ActionMailer::Base.deliveries.last.subject).to eq("New Join Request")
    end

    it "re-renders the form when required fields are missing" do
      expect do
        submit_demo(name: "", email: "", why: "")
      end.not_to(change { ActionMailer::Base.deliveries.count })

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "unknown paths on the join subdomain" do
    it "redirect to their apex equivalent" do
      get "http://join.lvh.me/events"
      expect(response).to redirect_to("http://lvh.me/events")
    end
  end

  describe "the apex" do
    it "is unaffected by the join site" do
      get "http://lvh.me/"
      expect(response).to be_successful
    end
  end
end
