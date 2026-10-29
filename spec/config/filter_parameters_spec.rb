# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Parameter filtering" do
  let(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

  it "hides tokens, API keys and emails from logged parameters" do
    filtered = filter.filter(
      "invitation_token" => "invite-secret",
      "reset_password_token" => "reset-secret",
      "calendar" => { "name" => "Gigs", "api_token" => "skl-secret" },
      "user" => { "email" => "someone@example.com", "password" => "hunter2" }
    )

    expect(filtered).to eq(
      "invitation_token" => "[FILTERED]",
      "reset_password_token" => "[FILTERED]",
      "calendar" => { "name" => "Gigs", "api_token" => "[FILTERED]" },
      "user" => { "email" => "[FILTERED]", "password" => "[FILTERED]" }
    )
  end

  it "hides a calendar's API token when it is inspected" do
    calendar = Calendar.new(name: "Gigs", api_token: "skl-secret")

    expect(calendar.inspect).not_to include("skl-secret")
    expect(calendar.inspect).to include("Gigs")
  end
end
