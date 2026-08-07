require "simplecov"
require "simplecov_json_formatter"
SimpleCov.start "rails" do
  enable_coverage :branch
  group "Datatables", "app/datatables"
  group "GraphQL", "app/graphql"
  group "Importers", "app/jobs/calendar_importer"
  group "Components", "app/components"
  group "Policies", "app/policies"
  group "Uploaders", "app/uploaders"

  if ENV["CI"]
    formatter SimpleCov::Formatter::MultiFormatter.new([
                                                         SimpleCov::Formatter::HTMLFormatter,
                                                         SimpleCov::Formatter::JSONFormatter
                                                       ])
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
end
