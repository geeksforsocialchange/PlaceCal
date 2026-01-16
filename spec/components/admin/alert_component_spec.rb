# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::AlertComponent, type: :component do
  it "renders with message" do
    render_inline(described_class.new(type: :notice, message: "Test message"))
    expect(page).to have_css(".alert")
    expect(page).to have_text("Test message")
  end

  describe "type variants" do
    it "renders notice type with info styling" do
      render_inline(described_class.new(type: :notice, message: "Info"))
      expect(page).to have_css(".alert.alert-info")
    end

    it "renders success type with success styling" do
      render_inline(described_class.new(type: :success, message: "Success"))
      expect(page).to have_css(".alert.alert-success")
    end

    it "renders alert type with warning styling" do
      render_inline(described_class.new(type: :alert, message: "Warning"))
      expect(page).to have_css(".alert.alert-warning")
    end

    it "renders error type with error styling" do
      render_inline(described_class.new(type: :error, message: "Error"))
      expect(page).to have_css(".alert.alert-error")
    end

    it "falls back to notice for unknown types" do
      render_inline(described_class.new(type: :unknown, message: "Unknown"))
      expect(page).to have_css(".alert.alert-info")
    end
  end

  it "renders appropriate icon" do
    render_inline(described_class.new(type: :notice, message: "Test"))
    expect(page).to have_css("svg") # icon is rendered
  end

  it "accepts string type and converts to symbol" do
    render_inline(described_class.new(type: "success", message: "String type"))
    expect(page).to have_css(".alert.alert-success")
  end
end
