# frozen_string_literal: true

require "rails_helper"

RSpec.describe Views::Admin::Components::Error, type: :phlex do
  let(:model) { Partner.new }

  context "when object has no errors" do
    it "renders nothing" do
      render_inline(described_class.new(model))
      expect(page.text).to be_blank
    end
  end

  context "when object has errors" do
    before do
      model.errors.add(:name, "can't be blank")
      model.errors.add(:slug, "is too short")
    end

    it "renders error alert" do
      render_inline(described_class.new(model))
      expect(page).to have_css(".alert.alert-error")
    end

    it "shows error count in header" do
      render_inline(described_class.new(model))
      expect(page).to have_css("h3.font-bold")
    end

    it "lists all error messages" do
      render_inline(described_class.new(model))
      expect(page).to have_css("li", count: 2)
      expect(page).to have_text("can't be blank")
      expect(page).to have_text("is too short")
    end

    it "renders warning icon" do
      render_inline(described_class.new(model))
      expect(page).to have_css("svg")
    end
  end
end
