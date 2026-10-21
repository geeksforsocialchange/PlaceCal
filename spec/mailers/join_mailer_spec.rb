# frozen_string_literal: true

require "rails_helper"

RSpec.describe JoinMailer, type: :mailer do
  let(:join_attrs) do
    { "name" => "Test User", "email" => "test@example.com", "why" => "I want to help my community" }
  end

  def join_us(site: nil, demo: false)
    described_class.join_us(attributes: join_attrs, site_id: site&.id, demo: demo)
  end

  describe "#join_us" do
    it "sends to the default recipient when there is no site" do
      mail = join_us

      expect(mail.to).to eq([ContactRequest::DEFAULT_RECIPIENT])
      expect(mail.subject).to eq(I18n.t("join_mailer.join_us.subject"))
    end

    it "sends to the site's contact_email and names the site in the subject" do
      site = create(:site, name: "Millbrook", contact_email: "hello@example.org")
      mail = join_us(site: site)

      expect(mail.to).to eq(["hello@example.org"])
      expect(mail.subject).to eq(I18n.t("join_mailer.join_us.subject_with_site", site: "Millbrook"))
    end

    it "keeps newlines in the site name out of the subject header" do
      site = create(:site, name: "Millbrook\r\nBcc: sneaky@example.com", contact_email: "hello@example.org")
      mail = join_us(site: site)

      expect(mail.subject).not_to include("\r")
      expect(mail.subject).not_to include("\n")
      expect(mail.subject).to include("MillbrookBcc: sneaky@example.com")
      expect(mail.bcc).to be_nil
    end

    it "uses the demo subject for a book-a-demo enquiry" do
      expect(join_us(demo: true).subject).to eq(I18n.t("join_mailer.join_us.subject_demo"))
    end

    it "falls back to the default recipient when the site has gone by delivery time" do
      mail = described_class.join_us(attributes: join_attrs, site_id: 0)

      expect(mail.to).to eq([ContactRequest::DEFAULT_RECIPIENT])
    end

    it "falls back to the default recipient when the site has no contact_email" do
      site = create(:site, contact_email: nil)
      mail = join_us(site: site)

      expect(mail.to).to eq([ContactRequest::DEFAULT_RECIPIENT])
    end
  end

  # The mail is rendered in a job, where Current is reset, so the mailer sets it
  # from the join's own site rather than trusting the caller's (#3368 D19).
  describe "theme-scoped copy" do
    let(:themed_site) { create(:site, name: "Themed", theme: "example_theme", contact_email: "hello@example.org") }

    before do
      I18n.backend.store_translations(
        :en,
        theme_overrides: {
          example_theme: {
            join_mailer: { join_us: { subject_with_site: "Fixture join request (%{site})" } } # rubocop:disable Style/FormatStringToken
          }
        }
      )
      Current.reset
    end

    it "uses the theme's override with no request to have set Current" do
      mail = join_us(site: themed_site)

      expect(mail.subject).to eq("Fixture join request (Themed)")
      expect(mail.body.encoded).to include("Test User")
    end

    it "renders under the join's own site, not whatever Current was left on" do
      use_current_site(build(:site, name: "Someone else", theme: "pink"))

      mail = join_us(site: themed_site)

      expect(mail.subject).to eq("Fixture join request (Themed)")
    end

    # Current.set, not assignment: a deliver_now inside a request, or a rake
    # task looping over deliveries, must get its own Current back rather than
    # inheriting this join's site for everything that follows.
    it "puts Current back the way it found it" do
      caller_site = use_current_site(build(:site, name: "Someone else", theme: "pink"))

      join_us(site: themed_site).subject

      expect(Current.site).to eq(caller_site)
      expect(Current.theme.name).to eq("pink")
    end

    it "uses the null theme's copy for a join with no site" do
      mail = join_us

      expect(mail.subject).to eq(I18n.t("join_mailer.join_us.subject"))
      expect(Current.theme).to eq(PlaceCal::Theme::NONE)
    end
  end
end
