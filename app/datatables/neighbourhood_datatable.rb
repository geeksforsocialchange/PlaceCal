# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
class NeighbourhoodDatatable < Datatable
  extend Forwardable

  LATEST_RELEASE_DATE = Neighbourhood::LATEST_RELEASE_DATE

  # Override to ensure draw is included
  def as_json(*)
    result = super
    result[:draw] = params[:draw].to_i if params[:draw].present?
    result
  end

  def view_columns
    @view_columns ||= {
      name: { source: 'Neighbourhood.name', cond: :like, searchable: true },
      unit: { source: 'Neighbourhood.unit', searchable: false, orderable: true },
      parent_name: { source: 'Neighbourhood.parent_name', searchable: false, orderable: true },
      unit_code_value: { source: 'Neighbourhood.unit_code_value', searchable: false, orderable: false },
      release_date: { source: 'Neighbourhood.release_date', searchable: false, orderable: true },
      actions: { source: 'Neighbourhood.id', searchable: false, orderable: false }
    }
  end

  def data
    records.map do |record|
      {
        name: render_name_cell(record),
        unit: render_unit_cell(record),
        parent_name: render_parent_cell(record),
        unit_code_value: render_unit_code_cell(record),
        release_date: render_release_cell(record),
        actions: render_actions(record)
      }
    end
  end

  def get_raw_records
    records = options[:neighbourhoods]

    # Apply filters from request params
    if params[:filter].present?
      # Unit type filter
      records = records.where(unit: params[:filter][:unit]) if params[:filter][:unit].present?

      # Release filter (current vs legacy)
      if params[:filter][:release].present?
        if params[:filter][:release] == 'current'
          records = records.where(release_date: LATEST_RELEASE_DATE)
        elsif params[:filter][:release] == 'legacy'
          records = records.where.not(release_date: LATEST_RELEASE_DATE)
        end
      end
    end

    records
  end

  def records_total_count
    options[:neighbourhoods].count
  end

  def records_filtered_count
    filter_records(get_raw_records).except(:limit, :offset, :order).count
  end

  private

  def render_name_cell(record)
    if can_view?(record)
      <<~HTML.html_safe
        <div class="flex flex-col">
          <a href="#{admin_neighbourhood_path(record)}" class="font-medium text-gray-900 hover:text-orange-600">
            #{ERB::Util.html_escape(record.name)}
          </a>
          <span class="text-xs text-gray-400">#{ERB::Util.html_escape(record.unit_name || record.unit)}</span>
        </div>
      HTML
    else
      <<~HTML.html_safe
        <div class="flex flex-col">
          <span class="font-medium text-gray-900">#{ERB::Util.html_escape(record.name)}</span>
          <span class="text-xs text-gray-400">#{ERB::Util.html_escape(record.unit_name || record.unit)}</span>
        </div>
      HTML
    end
  end

  def render_unit_cell(record)
    color_class = unit_color(record.unit)

    <<~HTML.html_safe
      <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium #{color_class}">
        #{ERB::Util.html_escape(record.unit&.titleize || 'Unknown')}
      </span>
    HTML
  end

  def unit_color(unit)
    case unit
    when 'ward'
      'bg-blue-100 text-blue-800'
    when 'district'
      'bg-purple-100 text-purple-800'
    when 'county'
      'bg-teal-100 text-teal-800'
    when 'region'
      'bg-amber-100 text-amber-800'
    when 'country'
      'bg-rose-100 text-rose-800'
    else
      'bg-gray-100 text-gray-800'
    end
  end

  def render_parent_cell(record)
    return '<span class="text-gray-400">—</span>'.html_safe if record.parent_name.blank?

    <<~HTML.html_safe
      <span class="text-gray-600">#{ERB::Util.html_escape(record.parent_name)}</span>
    HTML
  end

  def render_unit_code_cell(record)
    return '<span class="text-gray-400">—</span>'.html_safe if record.unit_code_value.blank?

    <<~HTML.html_safe
      <span class="text-gray-500 font-mono text-sm">#{ERB::Util.html_escape(record.unit_code_value)}</span>
    HTML
  end

  def render_release_cell(record)
    return '<span class="text-gray-400">—</span>'.html_safe unless record.release_date

    is_current = record.release_date == LATEST_RELEASE_DATE
    badge_class = is_current ? 'bg-emerald-100 text-emerald-800' : 'bg-gray-100 text-gray-600'
    badge_text = is_current ? 'Current' : 'Legacy'

    <<~HTML.html_safe
      <div class="flex items-center gap-2">
        <span class="text-gray-500 text-sm">#{record.release_date.strftime('%-d %b %Y')}</span>
        <span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium #{badge_class}">
          #{badge_text}
        </span>
      </div>
    HTML
  end

  def render_actions(record)
    if can_view?(record)
      <<~HTML.html_safe
        <div class="flex items-center gap-2">
          <a href="#{admin_neighbourhood_path(record)}"
             class="inline-flex items-center px-2.5 py-1.5 text-xs font-medium rounded text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500">
            View
          </a>
        </div>
      HTML
    else
      '<span class="text-gray-400">—</span>'.html_safe
    end
  end

  def can_view?(record)
    options[:current_user]&.can_view_neighbourhood_by_id?(record.id)
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
