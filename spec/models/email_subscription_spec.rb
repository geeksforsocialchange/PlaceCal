# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailSubscription, type: :model do
  let(:user) { create(:user) }

  describe "validations" do
    it { is_expected.to belong_to(:user) }

    it "rejects list keys not in the registry" do
      subscription = build(:email_subscription, user: user, list_key: "nonsense")
      expect(subscription).not_to be_valid
    end

    it "enforces one row per user and list" do
      create(:email_subscription, user: user)
      duplicate = build(:email_subscription, user: user)
      expect(duplicate).not_to be_valid
    end
  end

  describe ".subscribed?" do
    context "with no row" do
      it "falls back to the registry default: subscribed for opt-out lists" do
        expect(described_class.subscribed?(user, :partner_digest)).to be true
      end

      it "falls back to the registry default: not subscribed for opt-in lists" do
        expect(described_class.subscribed?(user, :partnership_updates)).to be false
      end
    end

    context "with an explicit row" do
      it "the row wins over an opt-out default" do
        described_class.set(user, :partner_digest, false, source: :unsubscribe_link)
        expect(described_class.subscribed?(user, :partner_digest)).to be false
      end

      it "the row wins over an opt-in default" do
        described_class.set(user, :partnership_updates, true, source: :profile_page)
        expect(described_class.subscribed?(user, :partnership_updates)).to be true
      end
    end

    it "raises for lists not in the registry" do
      expect { described_class.subscribed?(user, :nonsense) }.to raise_error(KeyError)
    end
  end

  describe ".set" do
    it "creates a row and an audit event" do
      expect { described_class.set(user, :partner_digest, false, source: :unsubscribe_link) }
        .to change(described_class, :count).by(1)
        .and change(EmailSubscriptionEvent, :count).by(1)

      event = EmailSubscriptionEvent.last
      expect(event.old_subscribed).to be_nil
      expect(event.new_subscribed).to be false
      expect(event.source).to eq "unsubscribe_link"
    end

    it "records old and new values when a row changes" do
      described_class.set(user, :partner_digest, false, source: :unsubscribe_link)
      described_class.set(user, :partner_digest, true, source: :profile_page)

      event = EmailSubscriptionEvent.last
      expect(event.old_subscribed).to be false
      expect(event.new_subscribed).to be true
    end

    it "records the actor when an admin makes the change" do
      admin = create(:root_user)
      described_class.set(user, :partner_digest, false, source: :admin, actor: admin)

      expect(EmailSubscriptionEvent.last.actor).to eq admin
    end

    it "is a no-op when the recorded state is unchanged" do
      row = described_class.set(user, :partner_digest, false, source: :unsubscribe_link)

      expect { described_class.set(user, :partner_digest, false, source: :profile_page) }
        .not_to change(EmailSubscriptionEvent, :count)
      expect(row.reload.source).to eq "unsubscribe_link"
    end
  end
end
