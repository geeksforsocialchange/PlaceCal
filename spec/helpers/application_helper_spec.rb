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
  end
end
