# frozen_string_literal: true

require "rails_helper"

RSpec.describe DemoRequest do
  it "is valid with a name and email" do
    expect(described_class.new(name: "A", email: "a@example.com")).to be_valid
  end

  it "requires name and email" do
    demo = described_class.new
    expect(demo).not_to be_valid
    expect(demo.errors.attribute_names).to include(:name, :email)
  end

  it "rejects an unknown audience" do
    demo = described_class.new(name: "A", email: "a@example.com", audience: "freelance-wizards")
    expect(demo).not_to be_valid
  end

  it "allows a blank audience" do
    expect(described_class.new(name: "A", email: "a@example.com", audience: "")).to be_valid
  end

  describe "#submit" do
    it "delivers the enquiry mail when valid" do
      demo = described_class.new(name: "A", email: "a@example.com")
      expect { demo.submit }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "does not deliver when invalid" do
      expect { described_class.new.submit }.not_to(change { ActionMailer::Base.deliveries.count })
    end
  end
end
