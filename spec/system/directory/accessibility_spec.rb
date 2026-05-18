# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Directory Accessibility", :slow, type: :system do
  include_context "normal island data"

  # Pre-existing site-wide violations to fix separately:
  # - color-contrast: nav "Join us" button, tertiary text, footer build link
  # - heading-order: event date headings skip from h1 to h3
  # - link-in-text-block: footer build link lacks distinguishing style
  # - aria-command-name: Leaflet map markers lack accessible names
  let(:axe_exclusions) { %w[color-contrast heading-order link-in-text-block aria-command-name] }

  describe "static pages" do
    it "homepage has no accessibility violations" do
      visit public_url("/")
      expect(page).to be_axe_clean.skipping(*axe_exclusions)
    end

    it "privacy page has no accessibility violations" do
      visit public_url("/privacy")
      expect(page).to be_axe_clean.skipping(*axe_exclusions)
    end

    it "terms of use page has no accessibility violations" do
      visit public_url("/terms-of-use")
      expect(page).to be_axe_clean.skipping(*axe_exclusions)
    end

    it "get in touch page has no accessibility violations" do
      visit public_url("/get-in-touch")
      expect(page).to be_axe_clean.skipping(*axe_exclusions)
    end
  end

  describe "partners" do
    it "partners index has no accessibility violations" do
      visit public_url("/partners")
      expect(page).to be_axe_clean.skipping(*axe_exclusions)
    end

    it "partner show has no accessibility violations" do
      visit public_url("/partners/#{riverside_hub.friendly_id}")
      expect(page).to be_axe_clean.skipping(*axe_exclusions)
    end
  end

  describe "events" do
    it "events index has no accessibility violations" do
      visit public_url("/events")
      expect(page).to be_axe_clean.skipping(*axe_exclusions)
    end

    it "event show has no accessibility violations" do
      visit public_url("/events/#{event_one.id}")
      expect(page).to be_axe_clean.skipping(*axe_exclusions)
    end
  end

  describe "partnerships" do
    it "partnerships index has no accessibility violations" do
      visit public_url("/partnerships")
      expect(page).to be_axe_clean.skipping(*axe_exclusions)
    end

    it "partnership show has no accessibility violations" do
      visit public_url("/partnerships/#{partnership_site.slug}")
      expect(page).to be_axe_clean.skipping(*axe_exclusions)
    end
  end
end
