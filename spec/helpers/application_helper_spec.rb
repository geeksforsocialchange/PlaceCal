# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#current_section?" do
    it "is current on the link's own page" do
      expect(helper.current_section?("/events", "/events")).to be(true)
      expect(helper.current_section?("/events?period=week", "/events")).to be(true)
    end

    it "stays current on pages beneath the link" do
      expect(helper.current_section?("/events/123", "/events")).to be(true)
      expect(helper.current_section?("/partners/some-partner", "/partners")).to be(true)
    end

    it "does not match a link that is only a prefix of the path" do
      expect(helper.current_section?("/eventsy", "/events")).to be(false)
      expect(helper.current_section?("/news", "/events")).to be(false)
    end

    it "only matches the root link on the root page" do
      expect(helper.current_section?("/", "/")).to be(true)
      expect(helper.current_section?("/?region=london", "/")).to be(true)
      expect(helper.current_section?("/events", "/")).to be(false)
    end

    it "is never current when the link has no path" do
      expect(helper.current_section?("/events", nil)).to be(false)
      expect(helper.current_section?("/events", "")).to be(false)
    end
  end

  describe "#current_page_path?" do
    it "is true only for the page the link points at" do
      expect(helper.current_page_path?("/events", "/events")).to be(true)
      expect(helper.current_page_path?("/events/", "/events")).to be(true)
      expect(helper.current_page_path?("/events?period=week", "/events")).to be(true)
      expect(helper.current_page_path?("/", "/")).to be(true)
    end

    it "is false for a page beneath the link" do
      expect(helper.current_page_path?("/events/123", "/events")).to be(false)
    end
  end

  describe "#active_link_to" do
    # aria-current="page" names the page being rendered; an ancestor section
    # link is aria-current="true".
    it "marks the link to this page as the current page" do
      allow(helper.request).to receive(:original_fullpath).and_return("/events")

      expect(helper.active_link_to("Events", "/events")).to include('aria-current="page"')
    end

    it "marks an ancestor section link as current, but not as the page" do
      allow(helper.request).to receive(:original_fullpath).and_return("/events/123")
      link = helper.active_link_to("Events", "/events")

      expect(link).to include('aria-current="true"')
      expect(link).not_to include('aria-current="page"')
    end

    it "sets no aria-current on a link that is not current" do
      allow(helper.request).to receive(:original_fullpath).and_return("/news")

      expect(helper.active_link_to("Events", "/events")).not_to include("aria-current")
    end

    it "emits no data attribute when none was given" do
      allow(helper.request).to receive(:original_fullpath).and_return("/news")

      expect(helper.active_link_to("Events", "/events")).not_to include("data=")
    end
  end
end
