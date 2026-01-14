# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ErrorComponent, type: :component do
  let(:partner) { Partner.new }

  context "when object has no errors" do
    it "renders nothing" do
      render_inline(described_class.new(partner))
      expect(page.text).to be_empty
    end
  end

  context "when object has errors" do
    before do
      partner.errors.add(:name, "can't be blank")
      partner.errors.add(:description, "is too short")
    end

    it "renders the error alert" do
      render_inline(described_class.new(partner))
      expect(page).to have_css(".alert.alert-error")
    end

    it "shows error count in title" do
      render_inline(described_class.new(partner))
      expect(page).to have_css("h3.font-bold", text: /2 errors/)
    end

    it "lists all error messages" do
      render_inline(described_class.new(partner))
      expect(page).to have_css("li", text: "Name can't be blank")
      expect(page).to have_css("li", text: "Description is too short")
    end

    it "includes the model name in the title" do
      render_inline(described_class.new(partner))
      expect(page).to have_text("Partner")
    end
  end

  describe "#errors_present?" do
    it "returns true when object has errors" do
      partner.errors.add(:name, "error")
      component = described_class.new(partner)
      expect(component.errors_present?).to be true
    end

    it "returns false when object has no errors" do
      component = described_class.new(partner)
      expect(component.errors_present?).to be false
    end
  end

  describe "#error_count" do
    it "returns the number of errors" do
      partner.errors.add(:name, "error1")
      partner.errors.add(:name, "error2")
      component = described_class.new(partner)
      expect(component.error_count).to eq(2)
    end
  end

  describe "#model_name" do
    it "returns the class name of the object" do
      component = described_class.new(partner)
      expect(component.model_name).to eq("Partner")
    end
  end
end
