# frozen_string_literal: true

require 'vcr'
require 'webmock/rspec'

VCR.configure do |c|
  # Use legacy cassettes during migration; update to spec/fixtures/vcr_cassettes after re-recording
  c.cassette_library_dir = 'test_legacy/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.ignore_localhost = true
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false
end

WebMock.disable_net_connect!(allow_localhost: true)
