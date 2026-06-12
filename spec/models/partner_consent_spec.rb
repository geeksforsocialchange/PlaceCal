# frozen_string_literal: true

require "rails_helper"

RSpec.describe PartnerConsent, type: :model do
  let(:partner) { create(:partner) }

  it "records basis, partner and who recorded it" do
    admin = create(:root_user)
    consent = described_class.create!(partner: partner, basis: "asked_in_person", recorded_by: admin)

    expect(consent.basis).to eq "asked_in_person"
    expect(consent.recorded_by).to eq admin
  end

  it "rejects bases outside the known list" do
    expect(described_class.new(partner: partner, basis: "vibes")).not_to be_valid
  end

  it "is append-only" do
    consent = described_class.create!(partner: partner, basis: "other")

    expect { consent.update!(basis: "asked_in_person") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { consent.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  describe "Partner#verify!" do
    it "publishes the partner and writes the consent record atomically" do
      hidden = create(:partner, hidden: true, hidden_reason: "Awaiting verification", hidden_blame_id: 1)

      hidden.verify!

      expect(hidden.reload.hidden).to be false
      expect(hidden.verified_at).to be_within(1.minute).of(Time.current)
      expect(hidden.partner_consents.last.basis).to eq "verified_by_email"
    end
  end
end
