# frozen_string_literal: true

# == Schema Information
#
# Table name: import_runs
#
#  id             :bigint           not null, primary key
#  error          :text
#  events_added   :integer          default(0), not null
#  events_changed :integer          default(0), not null
#  events_removed :integer          default(0), not null
#  events_skipped :integer          default(0), not null
#  finished_at    :datetime
#  importer       :string
#  notices        :jsonb            not null
#  outcome        :string
#  started_at     :datetime         not null
#  calendar_id    :bigint           not null
#
# Indexes
#
#  index_import_runs_on_calendar_id_and_started_at  (calendar_id,started_at)
#
# Foreign Keys
#
#  fk_rails_...  (calendar_id => calendars.id) ON DELETE => cascade
#
# One attempt to import a calendar: when it ran, how it ended and what it did to the calendar's events.
class ImportRun < ApplicationRecord
  OUTCOMES = %w[imported unchanged skipped error bad_source interrupted].freeze
  KEEP_UNCHANGED = 1.week
  KEEP = 1.month

  belongs_to :calendar
  has_many :events, class_name: 'ImportRunEvent', dependent: :delete_all

  validates :started_at, presence: true
  validates :outcome, inclusion: { in: OUTCOMES }, allow_nil: true

  scope :finished, -> { where.not(finished_at: nil) }
  scope :unfinished, -> { where(finished_at: nil) }
  scope :imported, -> { where(outcome: 'imported') }
  scope :latest_first, -> { order(started_at: :desc, id: :desc) }

  # 0.4 => "under a second", 4.2 => "4s", 83 => "1m 23s", 120 => "2m"
  def self.duration_label(seconds)
    return I18n.t('admin.import_runs.took.under_a_second') if seconds < 1

    minutes, secs = seconds.round.divmod(60)
    return I18n.t('admin.import_runs.took.seconds', count: secs) if minutes.zero?

    secs.zero? ? I18n.t('admin.import_runs.took.whole_minutes', count: minutes) : I18n.t('admin.import_runs.took.minutes', minutes:, seconds: secs)
  end

  # Closes runs whose worker stopped without finishing them
  def self.interrupt!(calendar_ids)
    unfinished.where(calendar_id: calendar_ids).update_all(outcome: 'interrupted', finished_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  # Unchanged checks go after a week and other runs after a month, but each calendar keeps its latest import
  def self.prune!
    latest_imports = imported.select('DISTINCT ON (calendar_id) id').order(:calendar_id, started_at: :desc, id: :desc)
    old = where(outcome: 'unchanged', started_at: ...KEEP_UNCHANGED.ago).or(where(started_at: ...KEEP.ago))
    old.where.not(id: latest_imports).delete_all
  end

  # @param outcome [String] one of OUTCOMES
  # @param events [Array<Hash>] ImportRunEvent attributes, kept only for an imported run
  def finish!(outcome:, events: [], **attributes)
    transaction do
      update!(outcome:, finished_at: Time.current, **attributes)
      next unless outcome == 'imported'

      # Only each calendar's latest import keeps its per-event rows; one feed can hold thousands
      ImportRunEvent.where(import_run: calendar.import_runs.where.not(id:)).delete_all
      ImportRunEvent.insert_all(events.map { it.merge(import_run_id: id) }) if events.any? # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
