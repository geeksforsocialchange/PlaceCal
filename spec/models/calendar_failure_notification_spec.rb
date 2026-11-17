# frozen_string_literal: true

require "rails_helper"

RSpec.describe Calendar::ImportState do
  let(:users) { create_list(:user, 2) }
  let(:organiser) { create(:partner, users:) }
  let(:calendar) { create(:calendar, organiser:) }
  let(:emails_enabled) { true }

  before do
    allow(CalendarImporterJob).to receive(:perform_later).and_return(nil)
    allow(described_class).to receive(:failure_emails_enabled?) { emails_enabled }
    calendar.update_columns(calendar_state: "in_worker") # rubocop:disable Rails/SkipsModelValidations
  end

  def run_import
    calendar.queue_for_import!(false)
    calendar.flag_start_import_job!
    yield
  end

  it "emails each of the organiser's users once when the source causes an error" do
    expect { calendar.flag_error_import_job!("Broken", notify: true) }
      .to have_enqueued_mail(CalendarImportMailer, :import_failed).with(calendar, users.first, state: "error", reason: "Broken").once
      .and have_enqueued_mail(CalendarImportMailer, :import_failed).with(calendar, users.second, state: "error", reason: "Broken").once
    expect(calendar.reload.failure_notified_at).to be_present
  end

  it "neither emails nor marks the calendar for an error on our side" do
    expect { calendar.flag_error_import_job!("Broken") }.not_to have_enqueued_mail
    expect(calendar.reload.failure_notified_at).to be_nil
  end

  it "emails the organiser's users when the calendar enters bad_source" do
    expect { calendar.flag_bad_source!("Not found") }
      .to have_enqueued_mail(CalendarImportMailer, :import_failed).with(calendar, users.first, state: "bad_source", reason: "Not found")
      .and have_enqueued_mail(CalendarImportMailer, :import_failed).with(calendar, users.second, state: "bad_source", reason: "Not found")
    expect(calendar.reload.failure_notified_at).to be_present
  end

  it "does not email again while the calendar keeps failing through the hourly cycle" do
    calendar.flag_bad_source!("Not found")

    expect do
      run_import { calendar.flag_bad_source!("Not found") }
      run_import { calendar.flag_error_import_job!("Broken", notify: true) }
    end.not_to have_enqueued_mail(CalendarImportMailer, :import_failed)
    expect(calendar.reload.calendar_state).to be_error
  end

  it "emails again when the calendar fails after a successful import" do
    calendar.flag_error_import_job!("Broken", notify: true)
    run_import { calendar.flag_complete_import_job!([], "ical") }
    expect(calendar.reload.failure_notified_at).to be_nil

    expect { run_import { calendar.flag_error_import_job!("Broken again", notify: true) } }
      .to have_enqueued_mail(CalendarImportMailer, :import_failed).exactly(2).times
  end

  it "does not count a skipped import as working again" do
    calendar.flag_bad_source!("Not found")
    run_import { calendar.flag_skipped_import_job!(["Skipped"]) }

    expect { run_import { calendar.flag_bad_source!("Not found") } }
      .not_to have_enqueued_mail(CalendarImportMailer, :import_failed)
  end

  it "emails an invited user who accepted, but not one whose invitation is pending" do
    users.first.update_columns(invitation_created_at: 1.day.ago, invitation_accepted_at: nil) # rubocop:disable Rails/SkipsModelValidations
    users.second.update_columns(invitation_created_at: 2.days.ago, invitation_accepted_at: 1.day.ago) # rubocop:disable Rails/SkipsModelValidations

    expect { calendar.flag_bad_source!("Not found") }
      .to have_enqueued_mail(CalendarImportMailer, :import_failed).once
      .and have_enqueued_mail(CalendarImportMailer, :import_failed).with(calendar, users.second, state: "bad_source", reason: "Not found")
  end

  context "when the organiser has no users" do
    let(:users) { [] }

    it "sends nothing and leaves the calendar unmarked, so users added later hear of the next failure" do
      expect { calendar.flag_error_import_job!("Broken", notify: true) }.not_to have_enqueued_mail
      expect(calendar.reload.failure_notified_at).to be_nil
    end
  end

  context "when the emails are switched off" do
    let(:emails_enabled) { false }

    it "sends nothing but marks the calendar as told" do
      expect { calendar.flag_bad_source!("Not found") }.not_to have_enqueued_mail
      expect(calendar.reload.failure_notified_at).to be_present
    end

    it "emails nobody about that failure once they are switched on" do
      calendar.flag_bad_source!("Not found")
      allow(described_class).to receive(:failure_emails_enabled?).and_return(true)

      expect { run_import { calendar.flag_error_import_job!("Broken", notify: true) } }.not_to have_enqueued_mail
    end
  end
end

RSpec.describe Calendar::ImportState, ".failure_emails_enabled?" do
  def enabled_in?(env, value)
    allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new(env))
    stub_const("ENV", ENV.to_hash.merge("CALENDAR_FAILURE_EMAILS_ENABLED" => value).compact)
    described_class.failure_emails_enabled?
  end

  it "is on only in production with the switch set to true", :aggregate_failures do
    expect(enabled_in?("production", "true")).to be(true)
    expect(enabled_in?("production", nil)).to be(false)
    expect(enabled_in?("production", "false")).to be(false)
    expect(enabled_in?("staging", "true")).to be(false)
    expect(enabled_in?("development", "true")).to be(false)
  end
end
