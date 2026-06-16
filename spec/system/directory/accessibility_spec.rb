# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Directory Accessibility", :slow, type: :system do
  include_context "normal island data"

  describe "static pages" do
    it "homepage has no accessibility violations" do
      visit public_url("/")
      expect(page).to be_axe_clean
    end

    it "privacy page has no accessibility violations" do
      visit public_url("/privacy")
      expect(page).to be_axe_clean
    end

    it "terms of use page has no accessibility violations" do
      visit public_url("/terms-of-use")
      expect(page).to be_axe_clean
    end

    it "get in touch page has no accessibility violations" do
      visit public_url("/get-in-touch")
      expect(page).to be_axe_clean
    end

    it "our story page has no accessibility violations" do
      visit public_url("/our-story")
      expect(page).to be_axe_clean
    end
  end

  describe "partners" do
    it "partners index has no accessibility violations" do
      visit public_url("/partners")
      expect(page).to be_axe_clean
    end

    it "partner show has no accessibility violations" do
      visit public_url("/partners/#{riverside_hub.slug}")
      expect(page).to be_axe_clean
    end
  end

  describe "events" do
    it "events index has no accessibility violations" do
      visit public_url("/events")
      expect(page).to be_axe_clean
    end
  end

  describe "partnerships" do
    it "partnerships index has no accessibility violations" do
      visit public_url("/partnerships")
      expect(page).to be_axe_clean
    end

    it "partnership show has no accessibility violations" do
      visit public_url("/partnerships/#{partnership_site.slug}")
      expect(page).to be_axe_clean
    end
  end
end
