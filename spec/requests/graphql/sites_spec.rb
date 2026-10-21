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

  # Fruit Salad's Elm site reads this API, so url keeps the exact strings
  # production returned before sites had a domain field (#2498).
  describe "url" do
    before { serve_hosts("placecal.org", "*.placecal.org", "www.queerleeds.lgbt", "transdimension.uk", "www.transdimension.uk") }

    let(:query) { "query($id: ID!) { site(id: $id) { url } }" }

    {
      ["hulme", nil] => "https://hulme.placecal.org",
      ["trans-dimension", "transdimension.uk"] => "https://transdimension.uk",
      ["queerleeds", "www.queerleeds.lgbt"] => "https://www.queerleeds.lgbt",
      ["fruitsaladevents", "fruitsaladevents.co.uk"] => "https://fruitsaladevents.co.uk/"
    }.each do |(slug, domain), expected|
      it "is #{expected} for #{slug}" do
        site = create(:site, slug:, domain:)
        result = execute_query(query, variables: { id: site.id })
        expect(result["data"]["site"]["url"]).to eq(expected)
      end
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
