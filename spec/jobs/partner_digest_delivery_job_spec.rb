# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnerDigestDeliveryJob do
  let(:user) { create(:partner_admin) }

  it "sends the digest and stamps partner_digest_last_sent_at" do
    expect { described_class.perform_now(user) }
      .to change(ActionMailer::Base.deliveries, :count).by(1)

    expect(user.reload.partner_digest_last_sent_at).to be_within(1.minute).of(Time.current)
  end

  it "is idempotent: a second run inside the interval does not double-send" do
    described_class.perform_now(user)

    expect { described_class.perform_now(user.reload) }
      .not_to change(ActionMailer::Base.deliveries, :count)
  end

  it "skips users with no partners" do
    partnerless = create(:user)

    expect { described_class.perform_now(partnerless) }
      .not_to change(ActionMailer::Base.deliveries, :count)
  end

  it "does not send or stamp last-sent for unsubscribed users" do
    EmailSubscription.set(user, :partner_digest, false, source: :unsubscribe_link)

    expect { described_class.perform_now(user) }
      .not_to change(ActionMailer::Base.deliveries, :count)

    # Keeping last-sent nil preserves the first-contact variant for if
    # they ever resubscribe
    expect(user.reload.partner_digest_last_sent_at).to be_nil
  end
end
