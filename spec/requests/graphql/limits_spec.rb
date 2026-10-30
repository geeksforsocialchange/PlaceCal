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
    expect(result["errors"].pluck("message")).to include(a_string_including("exceeds max depth of 10"))
  end

  it "rejects an over-deep query that mentions __schema in a comment" do
    result = execute_query("#{deep_query}\n# __schema")

    expect(result["data"]).to be_nil
    expect(result["errors"].pluck("message")).to include(a_string_including("exceeds max depth of 10"))
  end

  it "rejects an over-complex query that mentions __schema in a comment" do
    result = execute_query("#{complex_query}\n# __schema")

    expect(result["data"]).to be_nil
    expect(result["errors"].first["message"]).to include("exceeds max complexity of 1500")
  end

  it "rejects lists nested more than two deep" do
    query = "query { partnerConnection(first: 100) { nodes { events { organizer { events { organizer { events { organizer { events { summary } } } } } } } } } }"

    result = execute_query(query)

    expect(result["data"]).to be_nil
    expect(result["errors"].sole["message"]).to eq("Query nests lists 5 deep, which exceeds the maximum of 2")
  end

  describe "partners with their events and organisers" do
    let(:query) { "query { partnerConnection { nodes { id events { id organizer { id } } } } }" }

    def create_partners_with_events(count)
      create_list(:partner, count).each { |partner| create_list(:event, 5, organiser: partner, dtstart: 1.day.from_now) }
    end

    def count_queries(&)
      queries = 0
      counter = ->(*, payload) { queries += 1 unless payload[:cached] || %w[SCHEMA TRANSACTION].include?(payload[:name]) }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
      queries
    end

    it "loads them in the same few SQL queries however many partners there are" do
      create_partners_with_events(4)
      with_five = count_queries { execute_query(query) }

      create_partners_with_events(5)
      with_ten = count_queries { execute_query(query) }

      expect(response.parsed_body.dig("data", "partnerConnection", "nodes").sum { |node| node["events"].length }).to eq(45)
      expect(with_ten).to eq(with_five)
      expect(with_ten).to be <= 3
    end
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
