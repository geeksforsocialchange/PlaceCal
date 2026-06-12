# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecurringPartnerDigestJob do
  include ActiveJob::TestHelper

  before do
    # Don't let the self-rescheduling re-enqueue muddy the assertions
    setter = double("setter", perform_later: nil)
    allow(described_class).to receive(:set).and_return(setter)
  end

  context "when disabled (the default — launch gate)" do
    it "enqueues nothing even with due users" do
      create(:partner_admin)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(PartnerDigestDeliveryJob)
    end
  end

  context "when enabled" do
    before { allow(described_class).to receive(:enabled?).and_return(true) }

    it "enqueues one staggered delivery job per due user" do
      never_sent = create(:partner_admin)
      overdue = create(:partner_admin, partner_digest_last_sent_at: 91.days.ago)

      described_class.perform_now

      jobs = enqueued_jobs.select { |j| j["job_class"] == "PartnerDigestDeliveryJob" }
      expect(jobs.size).to eq 2
      expect(jobs.flat_map { |j| j["arguments"] }.map { |a| a["_aj_globalid"] })
        .to contain_exactly(never_sent.to_global_id.to_s, overdue.to_global_id.to_s)
    end

    it "skips users sent more recently than the interval" do
      create(:partner_admin, partner_digest_last_sent_at: 1.month.ago)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(PartnerDigestDeliveryJob)
    end

    it "skips users with no partners" do
      create(:user)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(PartnerDigestDeliveryJob)
    end

    it "skips unsubscribed users" do
      user = create(:partner_admin)
      EmailSubscription.set(user, :partner_digest, false, source: :unsubscribe_link)

      expect { described_class.perform_now }
        .not_to have_enqueued_job(PartnerDigestDeliveryJob)
    end
  end
end
