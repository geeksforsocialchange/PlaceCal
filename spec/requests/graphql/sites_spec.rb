# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL Sites", type: :request do
  def execute_query(query_string, variables: {})
    post "/api/v1/graphql", params: { query: query_string, variables: variables.to_json }
    response.parsed_body
  end

  describe "siteConnection query" do
    let!(:sites) { create_list(:site, 3) }

    let(:query) do
      <<-GRAPHQL
        query {
          siteConnection {
            edges {
              node {
                id
                name
                slug
              }
            }
          }
        }
      GRAPHQL
    end

    it "returns all sites with pagination" do
      result = execute_query(query)

      expect(result["errors"]).to be_nil
      expect(result["data"]["siteConnection"]["edges"].length).to eq(3)
    end
  end

  describe "site query" do
    let(:site) { create(:millbrook_site) }

    let(:query) do
      <<-GRAPHQL
        query($id: ID!) {
          site(id: $id) {
            id
            name
            slug
            description
          }
        }
      GRAPHQL
    end

    it "returns a specific site by ID" do
      result = execute_query(query, variables: { id: site.id })

      expect(result["errors"]).to be_nil
      expect(result["data"]["site"]["id"]).to eq(site.id.to_s)
      expect(result["data"]["site"]["name"]).to eq("Millbrook Community Calendar")
    end

    it "returns error for non-existent site" do
      result = execute_query(query, variables: { id: 999_999 })

      # GraphQL returns error when record not found
      expect(result["errors"]).to be_present
    end
  end
end
