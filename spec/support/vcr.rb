# frozen_string_literal: true

require "vcr"
require "webmock/rspec"

VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  c.hook_into :webmock
  c.ignore_localhost = true
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false

  # Ignore lvh.me requests (used for subdomain testing in system specs)
  c.ignore_hosts "lvh.me", "admin.lvh.me"

  # Filter sensitive API keys from cassettes
  c.before_record do |interaction|
    # Scrub Authorization headers, keeping the scheme (Ticket Tailor's Basic, Eventbrite's Bearer)
    if (authorization = interaction.request.headers["Authorization"])
      interaction.request.headers["Authorization"] = ["#{authorization.first.to_s.split.first} FILTERED"]
    end
  end

  # Eventbrite also echoes its token back in the X-Rate-Limit response header
  c.filter_sensitive_data("<EVENTBRITE_TOKEN>") { ENV.fetch("EVENTBRITE_TOKEN", nil) }
end

WebMock.disable_net_connect!(allow_localhost: true, allow: [/lvh\.me/])
