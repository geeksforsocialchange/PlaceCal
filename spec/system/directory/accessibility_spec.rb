# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Directory Accessibility", :slow, type: :system do
  include_context "normal island data"

  {
    "the homepage" => -> { "/" },
    "the privacy page" => -> { "/privacy" },
    "the terms of use page" => -> { "/terms-of-use" },
    "the sustainability page" => -> { "/sustainability" },
    "the accessibility statement" => -> { "/accessibility" },
    "the get in touch page" => -> { "/get-in-touch" },
    "our story" => -> { "/our-story" },
    "the partners listing" => -> { "/partners" },
    "a partner page" => -> { "/partners/#{riverside_hub.slug}" },
    "the events listing" => -> { "/events" },
    "an event page" => -> { "/events/#{event_one.id}" },
    "the partnerships listing" => -> { "/partnerships" },
    "a partnership page" => -> { "/partnerships/#{partnership_site.slug}" }
  }.each do |name, path|
    it "has no accessibility violations on #{name}" do
      visit public_url(instance_exec(&path))
      expect(page).to be_axe_clean
    end
  end
end
