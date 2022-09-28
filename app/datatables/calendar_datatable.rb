# frozen_string_literal: true

# Don't worry, this code will soon be purged from existence :)
require "action_view"
require "action_view/helpers"

class CalendarDatatable < Datatable
  include ActionView::Helpers::DateHelper

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id: {
        source: "Calendar.id",
        cond: :eq
      },
      name: {
        source: "Calendar.name"
      },
      partner: {
        source: "Calendar.partner",
        searchable: false,
        orderable: false
      },
      notice_count: {
        source: "Calendar.notice_count",
        searchable: false,
        orderable: false
      },
      events: {
        source: "Calendar.events",
        searchable: false,
        orderable: false
      },
      state: {
        source: "Calendar.calendar_state",
        searchable: false,
        orderable: false
      },
      last_import_at: {
        source: "Calendar.last_import_at",
        searchable: false,
        orderable: false
      },
      updated_at: {
        source: "Calendar.updated_at",
        searchable: false,
        orderable: false
      }
    }
  end

  def data
    records.map do |record|
      {
        id: link_to(record.id, edit_admin_calendar_path(record)),
        name: link_to(record.name, edit_admin_calendar_path(record)),
        partner: record.partner,
        notice_count: record.notice_count&.to_s || 0,
        events: record.events&.count&.to_s || 0,
        state: record.calendar_state,
        last_import_at: json_datetime(record.last_import_at),
        updated_at: json_datetime(record.updated_at)
      }
    end
  end

  def get_raw_records
    # insert query here
    # Calendar.all
    options[:calendars]
  end

  private

  def json_datetime(datetime)
    {
      unixtime: datetime.to_i,
      strtime: datetime ? "#{time_ago_in_words(datetime)} ago" : "never"
    }.to_json
  end
end
