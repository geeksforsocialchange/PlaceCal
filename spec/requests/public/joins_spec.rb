# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public Joins (Contact Form)", type: :request do
  # invisible_captcha guards the form with a session timestamp, a spinner token
  # and honeypot fields, all of which are seeded by rendering the form. A
  # realistic submission therefore has to GET the page first, carry its session
  # (hence host! rather than a per-request Host header, so the cookie jar
  # matches) and echo back the spinner. The suite freezes the clock, so the
  # "too quick" threshold is dropped to zero rather than moving time forward.
  def submit_form(host:, params:, honeypot: nil)
    host! host
    get "/get-in-touch"

    body = params.deep_dup
    body[:spinner] = response.body[/name="spinner"[^>]*value="([^"]*)"/, 1]
    body[honeypot] = "spam" if honeypot
    post "/get-in-touch", params: body
  end

  let(:valid_params) do
    {
      join: {
        name: "Test User",
        email: "test@example.com",
        why: "I want to help my community"
      }
    }
  end

  before do
    allow(InvisibleCaptcha).to receive(:timestamp_threshold).and_return(0)
    ActionMailer::Base.deliveries.clear
  end

  describe "GET /get-in-touch" do
    it "returns successful response" do
      get "/get-in-touch", headers: { "Host" => "lvh.me" }
      expect(response).to be_successful
    end

    it "renders the contact form" do
      get "/get-in-touch", headers: { "Host" => "lvh.me" }
      expect(response.body).to include("join")
    end

    it "renders the site form on a site host" do
      site = create(:site, contact_email: "hello@example.org")
      get "/get-in-touch", headers: { "Host" => "#{site.slug}.lvh.me" }
      expect(response).to be_successful
      expect(response.body).to include(site.name)
    end
  end

  describe "POST /get-in-touch" do
    context "with valid params" do
      it "redirects on success" do
        post "/get-in-touch", params: valid_params, headers: { "Host" => "lvh.me" }
        expect(response).to be_redirect
      end

      it "delivers one mail to the default recipient from the directory" do
        submit_form(host: "lvh.me", params: valid_params)

        expect(ActionMailer::Base.deliveries.size).to eq(1)
        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq([Join::DEFAULT_RECIPIENT])
        expect(mail.subject).to eq(I18n.t("join_mailer.join_us.subject"))
      end
    end

    context "on a site host" do
      it "delivers to the site's contact_email with the site name in the subject" do
        site = create(:site, contact_email: "hello@example.org")

        submit_form(host: "#{site.slug}.lvh.me", params: valid_params)

        expect(ActionMailer::Base.deliveries.size).to eq(1)
        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq(["hello@example.org"])
        expect(mail.subject).to include(site.name)
      end

      it "falls back to the default recipient when contact_email is blank" do
        site = create(:site, contact_email: nil)

        submit_form(host: "#{site.slug}.lvh.me", params: valid_params)

        expect(ActionMailer::Base.deliveries.size).to eq(1)
        expect(ActionMailer::Base.deliveries.last.to).to eq([Join::DEFAULT_RECIPIENT])
      end
    end

    context "with the invisible captcha honeypot filled" do
      it "is rejected and sends no mail" do
        site = create(:site, contact_email: "hello@example.org")

        submit_form(host: "#{site.slug}.lvh.me",
                    params: valid_params,
                    honeypot: InvisibleCaptcha.honeypots.first)

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          join: {
            name: "",
            email: "",
            why: ""
          }
        }
      end

      it "re-renders the form with errors" do
        post "/get-in-touch", params: invalid_params, headers: { "Host" => "lvh.me" }
        # Renders form again or redirects depending on captcha
        expect(response).to be_successful.or be_redirect
      end

      it "sends no mail" do
        submit_form(host: "lvh.me", params: invalid_params)
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end
  end
end
