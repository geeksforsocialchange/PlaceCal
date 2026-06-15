# frozen_string_literal: true

require 'pancal'
require 'active_support/testing/time_helpers'

Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

# Rails forces Encoding.default_external to UTF-8; plain Ruby derives it from
# the locale (US-ASCII under LANG=C), which breaks fixture reads and feed
# parsing in minimal environments. Match the environment the readers actually
# run in.
Encoding.default_external = Encoding::UTF_8

# Returns a Pathname for a file under spec/fixtures/files, mirroring
# Rails' file_fixture helper used by the original PlaceCal specs.
def file_fixture(name)
  Pathname.new(File.join(__dir__, 'fixtures', 'files', name))
end

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers

  # The original PlaceCal suite freezes time at 2022-11-08 (Europe/London).
  # The VCR cassettes were recorded around then, and LD+JSON events are
  # filtered on in_future?, so the gem suite must freeze to the same moment.
  config.before do
    Time.zone = 'Europe/London'
    travel_to Time.zone.local(2022, 11, 8)
  end

  config.after { travel_back }

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
