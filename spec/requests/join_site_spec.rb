# frozen_string_literal: true

require "rails_helper"

# The join marketing site (join.placecal.org, #3163), served entirely from
# the join subdomain: unknown paths there bounce to the apex.
RSpec.describe "Join marketing site", type: :request do
  describe "the join subdomain" do
    it "serves the homepage" do
      get "http://join.lvh.me/"
      expect(response).to be_successful
      expect(response.body).to include(I18n.t("join.home.hero.title"))
    end

    it "serves the audiences index" do
      get "http://join.lvh.me/who-its-for"
      expect(response).to be_successful
      expect(response.body).to include(I18n.t("join.audiences.index.title"))
    end

    Components::Join::Base::AUDIENCE_KEYS.each do |key|
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

    it "404s the underscored slug form so each audience page has one canonical URL" do
      get "http://join.lvh.me/who-its-for/community_groups"
      expect(response).to have_http_status(:not_found)
    end

    it "uses the marketing title on the homepage, not the directory branding" do
      get "http://join.lvh.me/"
      expect(response.body).to include("<title>#{I18n.t('join.home.title')} | PlaceCal</title>")
    end

    it "serves a crawlable robots.txt" do
      get "http://join.lvh.me/robots.txt"
      expect(response).to be_successful
      expect(response.body).not_to include("Disallow: /\n")
    end

    %w[/features /our-story /pricing /book-a-demo].each do |path|
      it "serves #{path}" do
        get "http://join.lvh.me#{path}"
        expect(response).to be_successful
      end
    end

    %w[/ /who-its-for /features /our-story /pricing /book-a-demo].each do |path|
      it "shows the work-in-progress notice on #{path}" do
        get "http://join.lvh.me#{path}"
        expect(response.body).to include(I18n.t("join.wip.heading"), I18n.t("join.wip.cta"))
      end

      it "asks search engines not to index #{path} while the copy is unagreed" do
        get "http://join.lvh.me#{path}"
        expect(response.body).to include('<meta name="robots" content="noindex, noarchive">')
      end
    end

    it "leaves the directory indexable" do
      get "http://lvh.me/"
      expect(response.body).to include('<meta name="robots" content="noarchive">')
    end

    it "has exactly one h1 on the homepage" do
      get "http://join.lvh.me/"
      expect(response.body.scan("<h1").size).to eq(1)
    end

    it "keeps acronyms in the audience kicker" do
      get "http://join.lvh.me/who-its-for/vcses"
      expect(response.body).to include(I18n.t("join.audiences.for_kicker", audience: I18n.t("join.audiences.vcses.title")))
    end

    it "uses one contact address across the site" do
      addresses = %w[/ /book-a-demo].flat_map do |path|
        get "http://join.lvh.me#{path}"
        response.body.scan(/mailto:([^"?]+)/).flatten
      end
      expect(addresses.uniq).to eq([I18n.t("contact.email")])
    end

    it "does not describe itself as the directory in structured data" do
      get "http://join.lvh.me/pricing"
      expect(response.body).not_to include("application/ld+json")
    end

    it "keeps the work-in-progress notice off the directory" do
      get "http://lvh.me/"
      expect(response.body).not_to include(I18n.t("join.wip.heading"))
    end

    it "renders the join chrome, not the directory chrome" do
      get "http://join.lvh.me/"
      expect(response.body).to include(I18n.t("join.band.host"))
      expect(response.body).to include(I18n.t("join.nav.book_demo"))
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
      expect(ActionMailer::Base.deliveries.last.subject).to eq(I18n.t("join_mailer.join_us.subject_demo"))
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

    it "redirect to the configured apex, not the request host, outside dev and test" do
      allow(Rails.env).to receive(:local?).and_return(false)
      get "http://join.evil.com/events"
      expect(response).to redirect_to("#{Site::DIRECTORY_URL}/events")
    end
  end

  describe "the apex" do
    it "is unaffected by the join site" do
      get "http://lvh.me/"
      expect(response).to be_successful
    end
  end
end
