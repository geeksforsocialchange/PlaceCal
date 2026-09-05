# frozen_string_literal: true

require "rails_helper"

RSpec.describe JoinMailer, type: :mailer do
  let(:join_attrs) do
    { name: "Test User", email: "test@example.com", why: "I want to help my community" }
  end

  describe "#join_us" do
    it "sends to the default recipient when there is no site" do
      mail = described_class.join_us(Join.new(**join_attrs))

      expect(mail.to).to eq([Join::DEFAULT_RECIPIENT])
      expect(mail.subject).to eq(I18n.t("join_mailer.join_us.subject"))
    end

    it "sends to the site's contact_email and names the site in the subject" do
      site = build(:site, name: "Millbrook", contact_email: "hello@example.org")
      mail = described_class.join_us(Join.new(site: site, **join_attrs))

      expect(mail.to).to eq(["hello@example.org"])
      expect(mail.subject).to eq(I18n.t("join_mailer.join_us.subject_with_site", site: "Millbrook"))
    end

    it "keeps newlines in the site name out of the subject header" do
      site = build(:site, name: "Millbrook\r\nBcc: sneaky@example.com", contact_email: "hello@example.org")
      mail = described_class.join_us(Join.new(site: site, **join_attrs))

      expect(mail.subject).not_to include("\r")
      expect(mail.subject).not_to include("\n")
      expect(mail.subject).to include("MillbrookBcc: sneaky@example.com")
      expect(mail.bcc).to be_nil
    end

    it "falls back to the default recipient when the site has no contact_email" do
      site = build(:site, contact_email: nil)
      mail = described_class.join_us(Join.new(site: site, **join_attrs))

      expect(mail.to).to eq([Join::DEFAULT_RECIPIENT])
    end
  end

  # The mail is rendered from the request today and from a job tomorrow, and
  # Current is reset between the two, so the mailer sets it from the join's own
  # site rather than trusting whatever the caller left behind (#3368 D19).
  describe "theme-scoped copy" do
    let(:themed_site) { build(:site, name: "Themed", theme: "example_theme", contact_email: "hello@example.org") }

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
      mail = described_class.join_us(Join.new(site: themed_site, **join_attrs))

      expect(mail.subject).to eq("Fixture join request (Themed)")
      expect(mail.body.encoded).to include("Test User")
    end

    it "renders under the join's own site, not whatever Current was left on" do
      use_current_site(build(:site, name: "Someone else", theme: "pink"))

      mail = described_class.join_us(Join.new(site: themed_site, **join_attrs))

      expect(mail.subject).to eq("Fixture join request (Themed)")
      expect(Current.site).to eq(themed_site)
    end

    it "leaves the null theme for a join with no site" do
      described_class.join_us(Join.new(**join_attrs)).body

      expect(Current.theme).to eq(PlaceCal::Theme::NONE)
    end
  end
end
