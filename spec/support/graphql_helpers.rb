# frozen_string_literal: true

# Helpers for GraphQL testing
module GraphQLHelpers
  def execute_query(query, variables: {}, context: {})
    PlaceCalSchema.execute(
      query,
      variables: variables,
      context: context
    )
  end

  def graphql_response
    JSON.parse(response.body)
  end

  # Assert a field exists in the result
  def expect_field(obj, key)
    expect(obj).to have_key(key), "Expected field '#{key}' to exist in: #{obj}"
    obj[key]
  end

  # Assert a field equals a value
  def expect_field_equals(obj, key, value)
    expect(obj).to have_key(key), "Expected field '#{key}' to exist"
    expect(obj[key]).to eq(value), "Expected '#{key}' to equal '#{value}', got '#{obj[key]}'"
  end

  # Assert a field does not exist
  def expect_no_field(obj, key)
    expect(obj).not_to have_key(key), "Expected field '#{key}' not to exist in: #{obj}"
  end
end

RSpec.configure do |config|
  config.include GraphQLHelpers, type: :request
  config.include GraphQLHelpers, graphql: true
end
