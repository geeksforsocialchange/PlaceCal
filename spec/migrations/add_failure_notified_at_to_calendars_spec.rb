# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("db/migrate/20261117022131_add_failure_notified_at_to_calendars.rb")

RSpec.describe AddFailureNotifiedAtToCalendars do
  subject(:migration) { described_class.new }

  before do
    ActiveRecord::Migration.verbose = false
    allow(CalendarImporterJob).to receive(:perform_later).and_return(nil)
  end

  # The test schema already has the column; the example's transaction rolls this back
  def migrate_up
    migration.migrate(:down)
    migration.migrate(:up)
    Calendar.reset_column_information
  end

  def calendar_in(state)
    create(:calendar).tap { |calendar| calendar.update_columns(calendar_state: state) } # rubocop:disable Rails/SkipsModelValidations
  end

  it "marks calendars already failing as notified, so deploying emails nobody" do
    failed = %w[error bad_source].map { |state| calendar_in(state) }

    migrate_up

    expect(failed.map { |calendar| calendar.reload.failure_notified_at }).to all(be_present)
  end

  it "leaves calendars that are not failing unmarked" do
    others = %w[idle in_queue in_worker].map { |state| calendar_in(state) }

    migrate_up

    expect(others.map { |calendar| calendar.reload.failure_notified_at }).to all(be_nil)
  end
end
