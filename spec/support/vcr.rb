# frozen_string_literal: true

require 'vcr'
require 'webmock/rspec'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.ignore_localhost = true
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false

  # Ignore lvh.me requests (used for subdomain testing in system specs)
  c.ignore_hosts 'lvh.me', 'admin.lvh.me', 'default-site.lvh.me'
end

WebMock.disable_net_connect!(allow_localhost: true, allow: [/lvh\.me/])
