# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL Partners", type: :request do
  def execute_query(query_string, variables: {})
    post "/api/v1/graphql", params: { query: query_string, variables: variables.to_json }
    response.parsed_body
  end

  describe "partnerConnection query" do
    let!(:partners) { create_list(:partner, 5) }

    let(:query) do
      <<-GRAPHQL
        query {
          partnerConnection {
            edges {
              node {
                id
                name
                summary
                description
              }
            }
          }
        }
      GRAPHQL
    end

    it "returns partners with pagination" do
      result = execute_query(query)

      expect(result["errors"]).to be_nil
      expect(result["data"]["partnerConnection"]["edges"].length).to eq(5)
    end

    it "includes partner details" do
      result = execute_query(query)

      edges = result["data"]["partnerConnection"]["edges"]
      partners.each_with_index do |partner, index|
        node = edges[index]["node"]
        expect(node["id"]).to eq(partner.id.to_s)
        expect(node["name"]).to eq(partner.name)
        expect(node["summary"]).to eq(partner.summary)
      end
    end
  end

  describe "partner query" do
    let(:partner) { create(:riverside_partner) }

    let(:query) do
      <<-GRAPHQL
        query($id: ID!) {
          partner(id: $id) {
            id
            name
            summary
            description
            url
            address {
              streetAddress
              postalCode
              addressLocality
              neighbourhood {
                name
                abbreviatedName
                unit
              }
            }
          }
        }
      GRAPHQL
    end

    it "returns a specific partner by ID" do
      result = execute_query(query, variables: { id: partner.id })

      expect(result["errors"]).to be_nil
      expect(result["data"]["partner"]["id"]).to eq(partner.id.to_s)
      expect(result["data"]["partner"]["name"]).to eq(partner.name)
    end

    it "includes address with neighbourhood" do
      result = execute_query(query, variables: { id: partner.id })

      address_data = result["data"]["partner"]["address"]
      expect(address_data["postalCode"]).to eq(partner.address.postcode)
      expect(address_data["neighbourhood"]).to be_present
      expect(address_data["neighbourhood"]["name"]).to eq("Riverside")
    end

    it "returns error for non-existent partner" do
      result = execute_query(query, variables: { id: 999_999 })

      # GraphQL returns error when record not found
      expect(result["errors"]).to be_present
    end
  end

  describe "partnersByTag query" do
    let(:category) { create(:category_tag) }
    let!(:tagged_partners) do
      create_list(:partner, 3).each { |p| p.tags << category }
    end
    let!(:untagged_partner) { create(:partner) }

    let(:query) do
      <<-GRAPHQL
        query($tagId: ID!) {
          partnersByTag(tagId: $tagId) {
            id
            name
          }
        }
      GRAPHQL
    end

    it "returns only partners with the specified tag" do
      result = execute_query(query, variables: { tagId: category.id })

      expect(result["errors"]).to be_nil
      partner_ids = result["data"]["partnersByTag"].map { |p| p["id"].to_i }

      tagged_partners.each do |partner|
        expect(partner_ids).to include(partner.id)
      end
      expect(partner_ids).not_to include(untagged_partner.id)
    end
  end
end
