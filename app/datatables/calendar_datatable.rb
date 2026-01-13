# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
class CalendarDatatable < Datatable
  # Override to ensure draw is included - parent class has issue with draw_id
  def as_json(*)
    result = super
    result[:draw] = params[:draw].to_i if params[:draw].present?
    result
  end

  def view_columns
    @view_columns ||= {
      name: { source: 'Calendar.name', cond: :like, searchable: true },
      partner: { source: 'partners.name', searchable: false, orderable: false },
      state: { source: 'Calendar.calendar_state', searchable: false, orderable: false },
      events: { source: 'Calendar.id', searchable: false, orderable: false },
      notices: { source: 'Calendar.notice_count', searchable: false, orderable: true },
      last_import_at: { source: 'Calendar.last_import_at', searchable: false, orderable: true },
      checksum_updated_at: { source: 'Calendar.checksum_updated_at', searchable: false, orderable: true },
      actions: { source: 'Calendar.id', searchable: false, orderable: false }
    }
  end

  def data
    records.map do |record|
      events_count = record.events.size
      {
        name: render_name_cell(record),
        partner: render_partner_cell(record),
        state: render_state_cell(record),
        events: render_count_cell(events_count, 'event'),
        notices: render_notices_cell(record),
        last_import_at: render_relative_time(record.last_import_at),
        checksum_updated_at: render_relative_time(record.checksum_updated_at),
        actions: render_actions(record)
      }
    end
  end

  def get_raw_records
    records = options[:calendars]
              .includes(:partner, :events)
              .left_joins(:partner)
              .references(:partner)

    # Apply filters from request params
    if params[:filter].present?
      # State filter
      records = records.where(calendar_state: params[:filter][:state]) if params[:filter][:state].present?

      # Partner filter
      records = records.where(partner_id: params[:filter][:partner]) if params[:filter][:partner].present?

      # Has events filter
      if params[:filter][:has_events].present?
        if params[:filter][:has_events] == 'yes'
          records = records.joins(:events).distinct
        elsif params[:filter][:has_events] == 'no'
          records = records.where.missing(:events)
        end
      end

      # Has notices filter
      if params[:filter][:has_notices].present?
        if params[:filter][:has_notices] == 'yes'
          records = records.where('calendars.notice_count > 0')
        elsif params[:filter][:has_notices] == 'no'
          records = records.where('calendars.notice_count = 0 OR calendars.notice_count IS NULL')
        end
      end
    end

    records
  end

  def records_total_count
    options[:calendars].count
  end

  def records_filtered_count
    filter_records(get_raw_records).except(:limit, :offset, :order).count
  end

  private

  def render_name_cell(record)
    <<~HTML.html_safe
      <div class="flex flex-col">
        <a href="#{edit_admin_calendar_path(record)}" class="font-medium text-gray-900 hover:text-orange-600">
          #{ERB::Util.html_escape(record.name)}
        </a>
        <span class="text-xs text-gray-400 font-mono">##{record.id}</span>
      </div>
    HTML
  end

  def render_partner_cell(record)
    partner = record.partner
    return '<span class="text-gray-400">—</span>'.html_safe unless partner

    <<~HTML.html_safe
      <button type="button"
              class="text-gray-600 hover:text-orange-600 hover:underline cursor-pointer text-left"
              data-action="click->admin-table#filterByValue"
              data-filter-column="partner"
              data-filter-value="#{partner.id}"
              title="Filter by #{ERB::Util.html_escape(partner.name)}">
        #{ERB::Util.html_escape(partner.name.truncate(30))}
      </button>
    HTML
  end

  def render_state_cell(record)
    state = record.calendar_state.to_s
    case state
    when 'idle'
      <<~HTML.html_safe
        <span class="inline-flex items-center text-emerald-600" title="Idle - ready for import">
          #{icon(:check)}
        </span>
      HTML
    when 'in_queue', 'in_worker'
      label = state == 'in_queue' ? 'Queued for import' : 'Importing...'
      <<~HTML.html_safe
        <span class="inline-flex items-center text-orange-500" title="#{label}">
          #{icon(:swap, css_class: 'animate-spin')}
        </span>
      HTML
    when 'error', 'bad_source'
      label = state == 'error' ? 'Import error' : 'Bad source URL'
      <<~HTML.html_safe
        <span class="inline-flex items-center text-red-600" title="#{label}">
          #{icon(:warning)}
        </span>
      HTML
    else
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-400" title="Unknown state">
          #{icon(:x)}
        </span>
      HTML
    end
  end

  def render_notices_cell(record)
    count = record.notice_count || 0
    if count.positive?
      <<~HTML.html_safe
        <span class="inline-flex items-center text-amber-600" title="#{count} notice#{'s' if count != 1}">
          #{icon(:warning)}
          <span class="ml-1 text-xs">#{count}</span>
        </span>
      HTML
    else
      <<~HTML.html_safe
        <span class="inline-flex items-center text-emerald-600" title="No notices">
          #{icon(:check)}
        </span>
      HTML
    end
  end

  def render_actions(record)
    <<~HTML.html_safe
      <div class="flex items-center gap-2">
        <a href="#{edit_admin_calendar_path(record)}"
           class="inline-flex items-center px-2.5 py-1.5 text-xs font-medium rounded text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500">
          Edit
        </a>
      </div>
    HTML
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
