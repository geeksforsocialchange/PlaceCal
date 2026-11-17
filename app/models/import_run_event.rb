# frozen_string_literal: true

# How one source event fared in its calendar's latest import.
# == Schema Information
#
# Table name: import_run_events
#
#  id              :bigint           not null, primary key
#  location        :text
#  location_result :string           not null
#  occurrences     :integer          default(0), not null
#  reason          :text
#  title           :string
#  uid             :string           not null
#  import_run_id   :bigint           not null
#
# Indexes
#
#  index_import_run_events_on_import_run_id  (import_run_id)
#
# Foreign Keys
#
#  fk_rails_...  (import_run_id => import_runs.id) ON DELETE => cascade
#
class ImportRunEvent < ApplicationRecord
  # The LocationResolver matches, plus failed (the calendar's settings couldn't place it) and skipped
  LOCATION_RESULTS = %w[matched_venue event_address default_location room none failed skipped].freeze

  belongs_to :import_run

  validates :location_result, inclusion: { in: LOCATION_RESULTS }
end
