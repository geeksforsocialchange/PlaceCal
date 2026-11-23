# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261117022131_add_failure_notified_at_to_calendars.rb")

RSpec.describe AddFailureNotifiedAtToCalendars do
  subject(:migration) { described_class.new }

  before do
    ActiveRecord::Migration.verbose = false
    allow(CalendarImporterJob).to receive(:perform_later).and_return(nil)
  end

  # Re-adding the column moves it to the end of the table, which outlives the rollback in prepared statements
  after do
    ActiveRecord::Base.connection.clear_cache!
    Calendar.reset_column_information
  end

  # The test schema already has the column; the example's transaction rolls this back
  def migrate_up
    migration.migrate(:down)
    migration.migrate(:up)
    Calendar.reset_column_information
  end

  def calendar_in(state, critical_error: nil)
    create(:calendar).tap { |calendar| calendar.update_columns(calendar_state: state, critical_error:) } # rubocop:disable Rails/SkipsModelValidations
  end

  it "marks calendars already failing as notified, so deploying emails nobody" do
    failed = %w[error bad_source].map { |state| calendar_in(state, critical_error: "Broken") }

    migrate_up

    expect(failed.map { |calendar| calendar.reload.failure_notified_at }).to all(be_present)
  end

  it "marks a failing calendar caught mid-retry by the hourly scan" do
    retrying = %w[in_queue in_worker idle].map { |state| calendar_in(state, critical_error: "Broken") }

    migrate_up

    expect(retrying.map { |calendar| calendar.reload.failure_notified_at }).to all(be_present)
  end

  it "leaves calendars that are not failing unmarked" do
    others = %w[idle in_queue in_worker].map { |state| calendar_in(state) }

    migrate_up

    expect(others.map { |calendar| calendar.reload.failure_notified_at }).to all(be_nil)
  end
end
