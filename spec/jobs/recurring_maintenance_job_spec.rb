# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecurringMaintenanceJob, type: :job do
  before do
    setter = double("setter")
    allow(described_class).to receive(:set).and_return(setter)
    allow(setter).to receive(:perform_later)
  end

  it "only tells search engines about changes from production" do
    allow(IndexNowSubmission).to receive(:new).and_call_original

    described_class.perform_now
    expect(IndexNowSubmission).not_to have_received(:new)

    allow(Rails.env).to receive(:production?).and_return(true)
    submission = instance_double(IndexNowSubmission, call: nil)
    allow(IndexNowSubmission).to receive(:new).and_return(submission)

    described_class.perform_now
    expect(submission).to have_received(:call)
    expect(IndexNowSubmission).to have_received(:new).with(since: be_within(1.minute).of(2.days.ago))
  end

  it "prunes versions older than a year" do
    old = PaperTrail::Version.create!(item_type: "Event", item_id: 1, event: "update", created_at: 2.years.ago)
    recent = PaperTrail::Version.create!(item_type: "Event", item_id: 2, event: "update", created_at: 1.day.ago)

    described_class.perform_now

    expect(PaperTrail::Version.exists?(old.id)).to be(false)
    expect(PaperTrail::Version.exists?(recent.id)).to be(true)
  end
end
