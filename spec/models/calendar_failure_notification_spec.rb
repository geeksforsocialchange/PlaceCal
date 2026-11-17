# frozen_string_literal: true

require "rails_helper"

RSpec.describe Calendar::ImportState do
  let(:users) { create_list(:user, 2) }
  let(:organiser) { create(:partner, users:) }
  let(:calendar) { create(:calendar, organiser:) }

  before do
    allow(CalendarImporterJob).to receive(:perform_later).and_return(nil)
    stub_const("ENV", ENV.to_hash.merge("CALENDAR_FAILURE_EMAILS_ENABLED" => "true"))
    calendar.update_columns(calendar_state: "in_worker") # rubocop:disable Rails/SkipsModelValidations
  end

  def run_import
    calendar.update_columns(calendar_state: "idle") # rubocop:disable Rails/SkipsModelValidations
    calendar.queue_for_import!(false)
    calendar.flag_start_import_job!
    yield
  end

  it "emails each of the organiser's users on their own when the calendar enters error" do
    expect { calendar.flag_error_import_job!("Broken") }
      .to have_enqueued_mail(CalendarImportMailer, :import_failed).with(calendar, users.first)
      .and have_enqueued_mail(CalendarImportMailer, :import_failed).with(calendar, users.second)
    expect(calendar.reload.failure_notified_at).to be_present
  end

  it "emails the organiser's users when the calendar enters bad_source" do
    expect { calendar.flag_bad_source!("Not found") }
      .to have_enqueued_mail(CalendarImportMailer, :import_failed).exactly(2).times
  end

  it "does not email again while the calendar keeps failing through the hourly cycle" do
    calendar.flag_bad_source!("Not found")

    expect do
      run_import { calendar.flag_bad_source!("Not found") }
      run_import { calendar.flag_error_import_job!("Broken") }
    end.not_to have_enqueued_mail(CalendarImportMailer, :import_failed)
    expect(calendar.reload.calendar_state).to be_error
  end

  it "emails again when the calendar fails after a successful import" do
    calendar.flag_error_import_job!("Broken")
    run_import { calendar.flag_complete_import_job!([], "ical") }
    expect(calendar.reload.failure_notified_at).to be_nil

    expect { run_import { calendar.flag_error_import_job!("Broken again") } }
      .to have_enqueued_mail(CalendarImportMailer, :import_failed).exactly(2).times
  end

  it "does not count a skipped import as working again" do
    calendar.flag_bad_source!("Not found")
    run_import { calendar.flag_skipped_import_job!(["Skipped"]) }

    expect { run_import { calendar.flag_bad_source!("Not found") } }
      .not_to have_enqueued_mail(CalendarImportMailer, :import_failed)
  end

  context "when the organiser has no users" do
    let(:users) { [] }

    it "sends nothing and leaves the calendar unmarked" do
      expect { calendar.flag_error_import_job!("Broken") }.not_to have_enqueued_mail
      expect(calendar.reload.failure_notified_at).to be_nil
    end
  end

  context "when the emails are switched off" do
    before { stub_const("ENV", ENV.to_hash.except("CALENDAR_FAILURE_EMAILS_ENABLED")) }

    it "sends nothing and leaves the calendar unmarked" do
      expect { calendar.flag_bad_source!("Not found") }.not_to have_enqueued_mail
      expect(calendar.reload.failure_notified_at).to be_nil
    end
  end
end
