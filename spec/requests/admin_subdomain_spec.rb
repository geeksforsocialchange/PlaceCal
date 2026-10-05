# frozen_string_literal: true

require "rails_helper"

# The admin subdomain has no Site row and is not the nationwide directory.
# Public routes carry no subdomain constraint, so a public path on the admin
# host used to fall through to the public controllers and raise on the nil
# site (e.g. Literal::TypeError in EventsController#index, #3267).
# A catch-all redirect now bounces these to the apex equivalent.
RSpec.describe "Admin subdomain public paths", type: :request do
  # Public-only paths (no matching admin route) fell through to the public
  # controllers and raised on the nil site. They must redirect to the apex.
  %w[/events /news /places].each do |path|
    it "redirects #{path} to the apex" do
      get "http://admin.lvh.me#{path}"
      expect(response).to redirect_to("http://lvh.me#{path}")
    end
  end

  it "preserves the query string when redirecting" do
    get "http://admin.lvh.me/events?period=week"
    expect(response).to redirect_to("http://lvh.me/events?period=week")
  end

  # Paths that exist as admin routes (e.g. /partners) keep hitting the
  # auth-gated admin controllers rather than bouncing to the apex.
  it "still serves real admin routes on the admin subdomain" do
    get "http://admin.lvh.me/partners"
    expect(response.location).not_to eq("http://lvh.me/partners")
  end
end
