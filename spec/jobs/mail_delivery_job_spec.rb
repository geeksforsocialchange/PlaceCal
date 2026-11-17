# frozen_string_literal: true

require "rails_helper"

RSpec.describe MailDeliveryJob, type: :job do
  it "delivers deliver_later mail" do
    expect(ActionMailer::Base.delivery_job).to eq(described_class)
  end

  it "retries a failed delivery, as delayed_job did" do
    allow_any_instance_of(ActionMailer::MailDeliveryJob).to receive(:perform).and_raise(Net::SMTPServerBusy) # rubocop:disable RSpec/AnyInstance

    expect { described_class.perform_now("JoinMailer", "join_us", "deliver_now", args: []) }
      .to have_enqueued_job(described_class)
  end
end
