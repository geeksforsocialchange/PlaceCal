# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event, ".prune_old_versions!" do
  # Distinct item_ids so PaperTrail's per-item version_limit doesn't delete rows first.
  def create_version(created_at)
    item_id = PaperTrail::Version.maximum(:item_id).to_i + 1
    PaperTrail::Version.create!(item_type: "Event", item_id:, event: "update", created_at:)
  end

  it "deletes versions older than a year and keeps newer ones" do
    create_version(2.years.ago)
    create_version(1.year.ago - 1.minute)
    just_new = create_version(1.year.ago + 1.minute)
    recent = create_version(1.day.ago)

    expect(described_class.prune_old_versions!).to eq(2)
    expect(PaperTrail::Version.pluck(:id)).to contain_exactly(just_new.id, recent.id)
  end

  it "deletes across more than one batch" do
    stub_const("Event::VERSION_PRUNE_BATCH_SIZE", 2)
    5.times { create_version(2.years.ago) }
    kept = create_version(1.day.ago)

    expect(described_class.prune_old_versions!).to eq(5)
    expect(PaperTrail::Version.pluck(:id)).to eq([kept.id])
  end

  it "logs how many versions were removed" do
    create_version(2.years.ago)
    allow(Rails.logger).to receive(:info)

    described_class.prune_old_versions!

    expect(Rails.logger).to have_received(:info).with(/Pruned 1 version/)
  end
end
