# frozen_string_literal: true

require 'vcr'
require 'webmock/rspec'

VCR.configure do |c|
  c.cassette_library_dir = File.expand_path('../fixtures/vcr_cassettes', __dir__)
  c.hook_into :webmock
  c.ignore_localhost = true
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false

  # Ignore schema.org requests (JSON-LD context loading)
  c.ignore_hosts 'schema.org', 'www.schema.org'

  # Filter sensitive API keys from cassettes
  c.before_record do |interaction|
    # Scrub Authorization headers (used by TicketTailor Basic Auth etc.)
    interaction.request.headers['Authorization'] = ['Basic FILTERED'] if interaction.request.headers['Authorization']
  end
end

WebMock.disable_net_connect!(allow: [/schema\.org/])
