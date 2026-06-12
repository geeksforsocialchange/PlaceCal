# frozen_string_literal: true

require "rails_helper"

RSpec.describe StagingMailInterceptor do
  def message_to(*recipients)
    Mail::Message.new(to: recipients, subject: "Test", body: "Hello")
  end

  it "leaves allowlisted recipients alone" do
    message = message_to("kim@gfsc.studio")

    described_class.delivering_email(message)

    expect(message.to).to eq ["kim@gfsc.studio"]
    expect(message.header["X-Original-To"]).to be_nil
  end

  it "redirects mail for real people to the fallback inbox, keeping a record" do
    message = message_to("partner@realcharity.org")

    described_class.delivering_email(message)

    expect(message.to).to eq ["support@placecal.org"]
    expect(message.header["X-Original-To"].value).to eq "partner@realcharity.org"
  end

  it "drops unsafe recipients from mixed lists" do
    message = message_to("kim@gfsc.studio", "partner@realcharity.org")

    described_class.delivering_email(message)

    expect(message.to).to eq ["kim@gfsc.studio"]
  end
end
