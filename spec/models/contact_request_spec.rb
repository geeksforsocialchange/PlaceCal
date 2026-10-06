# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContactRequest do
  it "is valid with name, email and why" do
    expect(described_class.new(name: "A", email: "a@example.com", why: "Community")).to be_valid
  end

  it "requires name, email and why" do
    contact_request = described_class.new
    expect(contact_request).not_to be_valid
    expect(contact_request.errors.attribute_names).to include(:name, :email, :why)
  end

  describe "#submit" do
    it "delivers the enquiry mail when valid" do
      contact_request = described_class.new(name: "A", email: "a@example.com", why: "Community")
      expect { contact_request.submit }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "does not deliver when invalid" do
      expect { described_class.new.submit }.not_to(change { ActionMailer::Base.deliveries.count })
    end
  end
end
