# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Devise User Invitation Mailer", type: :mailer do
  include EmailHelper

  it "sends an email when inviting a user" do
    user = User.new(email: "user@example.com")
    user.password = user.password_confirmation = "password"
    user.save!
    user.invite!

    last_email = last_email_delivered
    expect(last_email).to be_present
  end
end
