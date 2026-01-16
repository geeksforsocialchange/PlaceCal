# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
class NeighbourhoodDatatable < Datatable
  LATEST_RELEASE_DATE = Neighbourhood::LATEST_RELEASE_DATE

  def view_columns
    @view_columns ||= {
      name: { source: 'Neighbourhood.name', cond: :like, searchable: true },
      unit: { source: 'Neighbourhood.unit', searchable: false, orderable: true },
      hierarchy: { source: 'Neighbourhood.ancestry', searchable: false, orderable: false },
      partners_count: { source: 'Neighbourhood.partners_count', searchable: false, orderable: true },
      release_date: { source: 'Neighbourhood.release_date', searchable: false, orderable: true },
      actions: { source: 'Neighbourhood.id', searchable: false, orderable: false }
    }
  end

  def data
    records.map do |record|
      {
        name: render_name_cell(record),
        unit: render_unit_cell(record),
        hierarchy: render_hierarchy_cell(record),
        partners_count: render_partners_count_cell(record),
        release_date: render_release_cell(record),
        actions: render_actions(record)
      }
    end
  end

  def get_raw_records
    # Uses cached partners_count column (populated by migration, refreshed via Neighbourhood.refresh_partners_count!)
    records = options[:neighbourhoods]

    # Apply filters from request params
    if params[:filter].present?
      # Hierarchical filters - use the most specific one selected
      # Priority: district > county > region > country
      hierarchy_filter_id = nil
      %i[district_id county_id region_id country_id].each do |key|
        if params[:filter][key].present?
          hierarchy_filter_id = params[:filter][key]
          break
        end
      end

      if hierarchy_filter_id
        parent = Neighbourhood.find_by(id: hierarchy_filter_id)
        records = records.where(id: parent.subtree_ids) if parent
      end

      # Unit type filter
      records = records.where(unit: params[:filter][:unit]) if params[:filter][:unit].present?

      # Release filter (current vs legacy) - default to current if not specified
      release_filter = params[:filter][:release]
      if release_filter == 'current' || release_filter.blank?
        records = records.where(release_date: LATEST_RELEASE_DATE)
      elsif release_filter == 'legacy'
        records = records.where.not(release_date: LATEST_RELEASE_DATE)
      end
    else
      # Default to current release when no filters
      records = records.where(release_date: LATEST_RELEASE_DATE)
    end

    records
  end

  private

  def records_key
    :neighbourhoods
  end

  def edit_path_for(record)
    admin_neighbourhood_path(record)
  end

  def render_name_cell(record)
    subtitle = "##{record.id}"
    subtitle += " · §#{ERB::Util.html_escape(record.unit_code_value)}" if record.unit_code_value.present?
    if can_view?(record)
      <<~HTML.html_safe
        <div class="flex flex-col">
          <a href="#{admin_neighbourhood_path(record)}" class="font-medium text-gray-900 hover:text-orange-600">
            #{ERB::Util.html_escape(record.name)}
          </a>
          <span class="text-xs text-gray-500 font-mono">#{subtitle}</span>
        </div>
      HTML
    else
      <<~HTML.html_safe
        <div class="flex flex-col">
          <span class="font-medium text-gray-900">#{ERB::Util.html_escape(record.name)}</span>
          <span class="text-xs text-gray-500 font-mono">#{subtitle}</span>
        </div>
      HTML
    end
  end

  def render_unit_cell(record)
    colour_class = neighbourhood_colour(record.unit)

    <<~HTML.html_safe
      <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium #{colour_class}">
        #{ERB::Util.html_escape(record.unit&.titleize || 'Unknown')}
      </span>
    HTML
  end

  def neighbourhood_colour(level_or_unit)
    level = level_or_unit.is_a?(Integer) ? level_or_unit : Neighbourhood::LEVELS[level_or_unit&.to_sym]
    NeighbourhoodsHelper::LEVEL_COLOURS[level] || NeighbourhoodsHelper::DEFAULT_COLOUR
  end

  def render_hierarchy_cell(record)
    # Use the hierarchy badge component for full path display
    @view.render(
      Admin::NeighbourhoodHierarchyBadgeComponent.new(
        neighbourhood: record,
        max_levels: 4, # Show up to 4 levels
        truncate: true,
        link_each: false,
        compact: true
      )
    )
  end

  def render_partners_count_cell(record)
    count = record.try(:partners_count).to_i

    if count.positive?
      <<~HTML.html_safe
        <span class="inline-flex items-center justify-center min-w-[2rem] px-2 py-0.5 rounded-full text-sm font-medium bg-emerald-100 text-emerald-800">
          #{count}
        </span>
      HTML
    else
      '<span class="text-gray-500">—</span>'.html_safe
    end
  end

  def render_release_cell(record)
    return '<span class="text-gray-500">—</span>'.html_safe unless record.release_date

    is_current = record.release_date == LATEST_RELEASE_DATE
    badge_class = is_current ? 'bg-emerald-100 text-emerald-800' : 'bg-gray-100 text-gray-600'
    badge_text = is_current ? 'Current' : 'Legacy'

    <<~HTML.html_safe
      <div class="flex flex-col gap-1 whitespace-nowrap">
        <span class="text-gray-500 text-sm">#{record.release_date.strftime('%-d %b %Y')}</span>
        <span class="inline-flex items-center w-fit px-1.5 py-0.5 rounded text-xs font-medium #{badge_class}">
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
      '<span class="text-gray-500">—</span>'.html_safe
    end
  end

  def can_view?(record)
    options[:current_user]&.can_view_neighbourhood_by_id?(record.id)
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
