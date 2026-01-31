require "simplecov"
require "simplecov_json_formatter"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_group "Datatables", "app/datatables"
  add_group "GraphQL", "app/graphql"
  add_group "Importers", "app/jobs/calendar_importer"
  add_group "Components", "app/components"
  add_group "Policies", "app/policies"
  add_group "Uploaders", "app/uploaders"

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
