# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL query limits", type: :request do
  def execute_query(query_string)
    post "/api/v1/graphql", params: { query: query_string }
    response.parsed_body
  end

  # partnerConnection { nodes { events { organizer { events { ... } } } } } nested to depth 12
  let(:deep_query) do
    inner = "events { organizer { events { organizer { events { organizer { events { organizer { events { id } } } } } } } } }"
    "query { partnerConnection { nodes { #{inner} } } }"
  end

  let(:complex_query) do
    fields = (1..40).map { |i| "a#{i}: partnerConnection { nodes { id name summary description } }" }
    "query { #{fields.join(' ')} }"
  end

  before { create(:partner) }

  it "rejects a query deeper than the limit" do
    result = execute_query(deep_query)

    expect(result["data"]).to be_nil
    expect(result["errors"].first["message"]).to include("exceeds max depth of 10")
  end

  it "rejects an over-deep query that mentions __schema in a comment" do
    result = execute_query("#{deep_query}\n# __schema")

    expect(result["data"]).to be_nil
    expect(result["errors"].first["message"]).to include("exceeds max depth of 10")
  end

  it "rejects an over-complex query that mentions __schema in a comment" do
    result = execute_query("#{complex_query}\n# __schema")

    expect(result["data"]).to be_nil
    expect(result["errors"].first["message"]).to include("exceeds max complexity of 1500")
  end

  it "runs the standard introspection query" do
    result = execute_query(GraphQL::Introspection::INTROSPECTION_QUERY)

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "__schema", "queryType", "name")).to eq("Query")
  end

  it "runs a normal query" do
    result = execute_query("query { partnerConnection { nodes { id name } } }")

    expect(result["errors"]).to be_nil
    expect(result.dig("data", "partnerConnection", "nodes").length).to eq(1)
  end
end
