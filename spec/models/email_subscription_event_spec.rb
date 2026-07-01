# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailSubscriptionEvent, type: :model do
  let(:user) { create(:user) }

  let(:event) do
    EmailSubscription.set(user, :partner_digest, false, source: :unsubscribe_link)
    described_class.last
  end

  it "is append-only: rows cannot be updated" do
    expect { event.update!(new_subscribed: true) }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "is append-only: rows cannot be destroyed" do
    expect { event.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "is erased with the user's account" do
    event
    expect { user.destroy! }.to change(described_class, :count).to(0)
  end

  it "keeps events when only the actor's account is erased" do
    admin = create(:root_user)
    EmailSubscription.set(user, :partner_digest, false, source: :admin, actor: admin)

    expect { admin.destroy! }.not_to change(described_class, :count)
    expect(described_class.last.actor).to be_nil
  end
end
