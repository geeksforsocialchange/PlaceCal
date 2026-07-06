# frozen_string_literal: true

require "rails_helper"

RSpec.describe BroadcastRecipientsQuery do
  let(:partnership) { create(:partnership) }
  let(:partner_in) { create(:partner, tags: [partnership]) }
  let(:partner_out) { create(:partner) }

  let(:query) { described_class.new(partnership: partnership) }

  it "reaches admins of partners tagged with the partnership, once each" do
    admin = create(:user)
    admin.partners << partner_in
    second_partner = create(:partner, tags: [partnership])
    admin.partners << second_partner
    outsider = create(:user).tap { |u| u.partners << partner_out }

    expect(query.users).to contain_exactly(admin)
    expect(query.users).not_to include(outsider)
    expect(query.partners_count).to eq 2
  end

  it "filters eligibility through the partnership_updates opt-in and counts the excluded" do
    opted_in = create(:user).tap { |u| u.partners << partner_in }
    not_opted = create(:user).tap { |u| u.partners << partner_in }
    EmailSubscription.set(opted_in, :partnership_updates, true, source: :profile_page)

    expect(query.users).to contain_exactly(opted_in, not_opted)
    expect(query.eligible).to contain_exactly(opted_in)
    expect(query.excluded_count).to eq 1
  end
end
