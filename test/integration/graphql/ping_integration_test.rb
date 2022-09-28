# frozen_string_literal: true

require "test_helper"

class GraphQLPingTest < ActionDispatch::IntegrationTest
  test "it returns a string" do
    query_string = <<-GRAPHQL
      query {
        ping
      }
    GRAPHQL

    result = PlaceCalSchema.execute(query_string)
    data = result["data"]
    assert data.has_key?("ping")

    assert data["ping"] =~
             /^Hello World! The time is \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
  end
end
