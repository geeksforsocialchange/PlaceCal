class CalendarDatatable < Datatable
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id: { source: 'Calendar.id', cond: :eq },
      name: { source: 'Calendar.name' },
      partner: { source: 'Calendar.partner', searchable: false, orderable: false },
      place: { source: 'Calendar.place', searchable: false, orderable: false },
      is_working: { source: 'Calendar.is_working' },
      last_import_at: { source: 'Calendar.last_import_at' },
      updated_at: { source: 'Calendar.updated_at' }
    }
  end

  def data
    records.map do |record|
      {
        id: link_to(record.id, edit_admin_calendar_path(record)),
        name: link_to(record.name, edit_admin_calendar_path(record)),
        partner: record.partner,
        place: record.place,
        is_working: record.is_working,
        last_import_at: record.last_import_at,
        updated_at: record.updated_at
      }
    end
  end

  def get_raw_records
    # insert query here
    # Calendar.all
    options[:calendars]
  end
end
