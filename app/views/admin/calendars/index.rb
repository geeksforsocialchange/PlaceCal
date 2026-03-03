# frozen_string_literal: true

class Views::Admin::Calendars::Index < Views::Admin::Base
  register_value_helper :icon_column_header

  prop :calendars, ActiveRecord::Relation, reader: :private
  prop :partner_options, Array, reader: :private
  prop :importer_options, Array, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    Datatable(
      title: 'Calendars',
      model: :calendars,
      column_titles: [
        'Calendar', 'Partner',
        icon_column_header(:import, 'Status'),
        icon_column_header(:event, 'Events'),
        icon_column_header(:search_alert, 'Notices'),
        'Importer', 'Last Import', 'Source Updated', ''
      ],
      columns: %i[name partner state events notices importer last_import_at checksum_updated_at actions],
      column_config: {
        name: {},
        partner: { sortable: false },
        state: { align: :center, sortable: false, fit: true },
        importer: { fit: true },
        events: { align: :center, sortable: false, fit: true },
        notices: { align: :center, fit: true },
        last_import_at: { fit: true },
        checksum_updated_at: { fit: true },
        actions: { sortable: false, fit: true }
      },
      default_sort: { column: 'last_import_at', direction: 'desc' },
      filters: calendars_filters,
      data: calendars,
      source: admin_calendars_path(format: :json),
      new_link: new_admin_calendar_path
    )
  end

  private

  def calendars_filters # rubocop:disable Metrics/MethodLength
    [
      { type: :radio, column: 'has_events', label: 'Events',
        options: [{ value: 'yes', label: 'Yes' }, { value: 'no', label: 'No' }] },
      { type: :radio, column: 'has_notices', label: 'Notices',
        options: [{ value: 'yes', label: 'Yes' }, { value: 'no', label: 'No' }] },
      { column: 'state', label: 'Status', width: 'w-32',
        options: [{ value: 'idle', label: 'Idle' }, { value: 'in_queue', label: 'In Queue' },
                  { value: 'in_worker', label: 'Importing' }, { value: 'error', label: 'Error' },
                  { value: 'bad_source', label: 'Bad Source' }] },
      { column: 'partner', label: 'Partner', tom_select: true, width: 'w-48',
        options: partner_options },
      { column: 'importer', label: 'Importer', width: 'w-36',
        options: importer_options }
    ]
  end
end
