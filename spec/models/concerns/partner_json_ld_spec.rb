# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnerJsonLd do
  let(:schema_path) { Rails.root.join("spec/support/schemas/schema_org_organization.json") }
  let(:schema) { JSON.parse(File.read(schema_path)) }

  describe "#to_json_ld" do
    let(:partner) { create(:partner) }
    let(:data) { partner.to_json_ld }

    it "validates against the schema.org Organization JSON Schema" do
      errors = JSON::Validator.fully_validate(schema, data)
      expect(errors).to be_empty, -> { "JSON-LD validation errors:\n#{errors.join("\n")}" }
    end

    it "includes required fields" do
      expect(data["@context"]).to eq("https://schema.org")
      expect(data["@type"]).to eq("Organization")
      expect(data["name"]).to eq(partner.name)
    end

    context "with url" do
      it "includes url when present" do
        partner.update!(url: "https://example.org")
        expect(partner.to_json_ld["url"]).to eq("https://example.org")
      end

      it "omits url when blank" do
        partner.update!(url: "")
        expect(partner.to_json_ld).not_to have_key("url")
      end
    end

    context "with contact info" do
      it "includes telephone when present" do
        partner.update!(public_phone: "0161 123 4567")
        expect(partner.to_json_ld["telephone"]).to eq("0161 123 4567")
      end

      it "includes email when present" do
        partner.update!(public_email: "info@example.org")
        expect(partner.to_json_ld["email"]).to eq("info@example.org")
      end

      it "omits telephone and email when blank" do
        partner.update!(public_phone: "", public_email: "")
        result = partner.to_json_ld
        expect(result).not_to have_key("telephone")
        expect(result).not_to have_key("email")
      end
    end

    context "with social links" do
      it "includes sameAs with twitter and instagram" do
        partner.update!(twitter_handle: "testorg", instagram_handle: "testorg")
        same_as = partner.to_json_ld["sameAs"]
        expect(same_as).to include("https://twitter.com/testorg")
        expect(same_as).to include("https://instagram.com/testorg")
      end

      it "includes facebook in sameAs" do
        partner.update!(facebook_link: "testorg")
        same_as = partner.to_json_ld["sameAs"]
        expect(same_as).to include("https://facebook.com/testorg")
      end

      it "omits sameAs when no social links" do
        partner.update!(twitter_handle: "", instagram_handle: "", facebook_link: "")
        expect(partner.to_json_ld).not_to have_key("sameAs")
      end
    end

    context "with address" do
      it "includes PostalAddress" do
        address = data["address"]
        expect(address["@type"]).to eq("PostalAddress")
        expect(address["streetAddress"]).to be_present
      end
    end

    context "without address" do
      let(:partner) { create(:partner, address: nil, service_areas: [create(:service_area)]) }

      it "omits address key" do
        expect(data).not_to have_key("address")
      end
    end

    context "with description" do
      it "strips HTML from summary" do
        partner.update!(summary: "<p>A great <em>community</em> group</p>")
        expect(partner.to_json_ld["description"]).to eq("A great community group")
      end
    end
  end
end
