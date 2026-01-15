# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
class PartnerDatatable < Datatable
  def view_columns
    # Order must match columns array in index.html.erb
    @view_columns ||= {
      name: { source: 'Partner.name', cond: :like, searchable: true },
      ward: { source: 'ward_neighbourhoods.name', searchable: false, orderable: false },
      partnerships: { source: 'Partner.id', searchable: false, orderable: false },
      calendars: { source: 'Partner.id', searchable: false, orderable: false },
      admins: { source: 'Partner.id', searchable: false, orderable: false },
      categories: { source: 'Partner.id', searchable: false, orderable: false },
      updated_at: { source: 'Partner.updated_at', searchable: false, orderable: true },
      actions: { source: 'Partner.id', searchable: false, orderable: false }
    }
  end

  def data
    records.map do |record|
      calendars_count = record.calendars.size
      users_count = record.users.size
      partnerships = record.tags.select { |t| t.type == 'Partnership' }
      categories_count = record.tags.count { |t| t.type == 'Category' }

      {
        name: render_name_cell(record),
        ward: render_ward_cell(record),
        partnerships: render_partnerships(partnerships),
        calendars: render_calendar_status(record, calendars_count),
        admins: render_tick_cross(users_count.positive?, "#{users_count} admin#{'s' if users_count != 1}", 'No admins'),
        categories: render_tick_cross(categories_count.positive?, "#{categories_count} categor#{'y' if categories_count == 1}#{'ies' if categories_count != 1}", 'No categories'),
        updated_at: render_updated_at(record),
        actions: render_actions(record)
      }
    end
  end

  def get_raw_records
    # Join addresses and neighbourhoods for sorting by ward
    records = options[:partners]
              .includes(:calendars, :users, :tags, address: :neighbourhood, service_areas: :neighbourhood)
              .left_joins(:calendars, :users, address: :neighbourhood)
              .joins('LEFT JOIN addresses ON addresses.id = partners.address_id')
              .joins('LEFT JOIN neighbourhoods AS ward_neighbourhoods ON ward_neighbourhoods.id = addresses.neighbourhood_id')
              .select('partners.*, COUNT(DISTINCT calendars.id) as calendars_count, COUNT(DISTINCT users.id) as users_count')
              .group('partners.id')

    # Apply filters from request params
    if params[:filter].present?
      # Calendar status filter
      case params[:filter][:calendar_status]
      when 'connected'
        records = records.having('COUNT(DISTINCT calendars.id) > 0')
      when 'none'
        records = records.having('COUNT(DISTINCT calendars.id) = 0')
      end

      # Has admins filter
      if params[:filter][:has_admins] == 'yes'
        records = records.having('COUNT(DISTINCT users.id) > 0')
      elsif params[:filter][:has_admins] == 'no'
        records = records.having('COUNT(DISTINCT users.id) = 0')
      end

      # Hierarchical neighbourhood filters - find partners within selected area
      records = apply_neighbourhood_filter(records, params[:filter])

      # Legacy ward filter (for backwards compatibility with existing ward column clicks)
      records = records.where(ward_neighbourhoods: { id: params[:filter][:ward] }) if params[:filter][:ward].present?

      # Partnership filter
      if params[:filter][:partnership].present?
        partner_ids = Partner.joins(:tags).where(tags: { id: params[:filter][:partnership], type: 'Partnership' }).pluck(:id)
        records = records.where(id: partner_ids)
      end

      # Category filter
      if params[:filter][:category].present?
        partner_ids = Partner.joins(:tags).where(tags: { id: params[:filter][:category], type: 'Category' }).pluck(:id)
        records = records.where(id: partner_ids)
      end
    end

    records
  end

  # Override to handle GROUP BY correctly - count returns a hash with GROUP BY
  def records_filtered_count
    # Filtered count includes our custom filters AND the DataTables search
    # We need to keep HAVING clauses since calendar/admin filters use them
    records = filter_records(fetch_records).unscope(:limit, :offset, :order)

    # Count using a subquery to preserve GROUP BY and HAVING
    subquery = records.except(:select).select('partners.id')
    Partner.from(subquery, :partners).count
  end

  private

  def records_key
    :partners
  end

  # Apply hierarchical neighbourhood filter (country/region/county/district/ward)
  # Returns records filtered to partners within the selected area
  def apply_neighbourhood_filter(records, filter)
    # Check from most specific to least specific
    neighbourhood_filter_id = filter[:ward_id].presence ||
                              filter[:district_id].presence ||
                              filter[:county_id].presence ||
                              filter[:region_id].presence ||
                              filter[:country_id].presence

    return records if neighbourhood_filter_id.blank?

    neighbourhood = Neighbourhood.find_by(id: neighbourhood_filter_id)
    return records unless neighbourhood

    # Get all ward IDs that are descendants of this neighbourhood (or the neighbourhood itself if it's a ward)
    ward_ids = neighbourhood.unit == 'ward' ? [neighbourhood.id] : neighbourhood.descendants.where(unit: 'ward').pluck(:id)

    return records if ward_ids.empty?

    records.where(ward_neighbourhoods: { id: ward_ids })
  end

  def edit_path_for(record)
    edit_admin_partner_path(record)
  end

  def render_name_cell(record)
    <<~HTML.html_safe
      <div class="flex flex-col">
        <a href="#{edit_admin_partner_path(record)}" class="font-medium text-gray-900 hover:text-orange-600">
          #{ERB::Util.html_escape(record.name)}
        </a>
        <span class="text-xs text-gray-400 font-mono">##{record.id} · /#{ERB::Util.html_escape(record.slug)}</span>
      </div>
    HTML
  end

  def render_ward_cell(record)
    # Collect all unique neighbourhoods from address and service areas
    neighbourhoods = []
    neighbourhoods << record.address.neighbourhood if record.address&.neighbourhood
    record.service_areas.each do |sa|
      neighbourhoods << sa.neighbourhood if sa.neighbourhood
    end
    neighbourhoods = neighbourhoods.uniq

    if neighbourhoods.empty?
      <<~HTML.html_safe
        <span class="text-gray-400">—</span>
      HTML
    else
      # Show first 2 wards, with "and X more" for additional
      visible = neighbourhoods.first(2)
      remaining = neighbourhoods.size - 2

      buttons = visible.map do |neighbourhood|
        name = neighbourhood.shortname
        display_name = name.length > 18 ? "#{name[0..15]}..." : name

        <<~BUTTON.strip
          <button type="button"
                  class="block text-left text-gray-600 hover:text-orange-600 hover:underline cursor-pointer truncate max-w-[140px]"
                  data-action="click->admin-table#filterByValue"
                  data-filter-column="ward"
                  data-filter-value="#{neighbourhood.id}"
                  title="Filter by #{ERB::Util.html_escape(name)}">#{ERB::Util.html_escape(display_name)}</button>
        BUTTON
      end

      more_text = remaining.positive? ? "<span class=\"text-gray-500 text-xs\">and #{remaining} more...</span>" : ''

      <<~HTML.html_safe
        <div class="text-sm space-y-0.5">
          #{buttons.join("\n")}
          #{more_text}
        </div>
      HTML
    end
  end

  def render_calendar_status(record, count)
    calendars = record.calendars

    if calendars.empty?
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-400" title="No calendars">
          #{icon(:x)}
        </span>
      HTML
    else
      # Check for any calendars with errors
      error_calendars = calendars.select { |c| c.calendar_state.to_s.in?(%w[error bad_source]) }

      if error_calendars.any?
        <<~HTML.html_safe
          <span class="inline-flex items-center text-red-600" title="#{error_calendars.size} calendar#{'s' if error_calendars.size != 1} with errors">
            #{icon(:warning)}
          </span>
        HTML
      else
        <<~HTML.html_safe
          <span class="inline-flex items-center text-emerald-600" title="#{count} calendar#{'s' if count != 1} connected">
            #{icon(:check)}
          </span>
        HTML
      end
    end
  end

  def render_tick_cross(has_items, title_yes, title_no)
    if has_items
      <<~HTML.html_safe
        <span class="inline-flex items-center text-emerald-600" title="#{title_yes}">
          #{icon(:check)}
        </span>
      HTML
    else
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-400" title="#{title_no}">
          #{icon(:x)}
        </span>
      HTML
    end
  end

  def render_partnerships(partnerships)
    if partnerships.empty?
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-400" title="No partnerships">
          #{icon(:x)}
        </span>
      HTML
    else
      # Show first 2 partnerships, abbreviate long names
      visible = partnerships.first(2)
      remaining = partnerships.size - 2

      buttons = visible.map do |p|
        name = p.name
        display_name = name.length > 20 ? "#{name[0..17]}..." : name

        <<~BUTTON.strip
          <button type="button"
                  class="block text-left text-gray-700 hover:text-orange-600 hover:underline cursor-pointer truncate max-w-[150px]"
                  data-action="click->admin-table#filterByValue"
                  data-filter-column="partnership"
                  data-filter-value="#{p.id}"
                  title="Filter by #{ERB::Util.html_escape(name)}">#{ERB::Util.html_escape(display_name)}</button>
        BUTTON
      end

      more_text = remaining.positive? ? "<span class=\"text-gray-500 text-xs\">and #{remaining} more...</span>" : ''

      <<~HTML.html_safe
        <div class="text-sm space-y-0.5">
          #{buttons.join("\n")}
          #{more_text}
        </div>
      HTML
    end
  end

  def render_updated_at(record)
    render_relative_time(record.updated_at)
  end

  def render_actions(record)
    <<~HTML.html_safe
      <div class="flex items-center gap-2">
        <a href="#{edit_admin_partner_path(record)}"
           class="inline-flex items-center px-2.5 py-1.5 text-xs font-medium rounded text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500">
          Edit
        </a>
        <div class="relative" data-controller="dropdown">
          <button type="button"
                  data-action="click->dropdown#toggle"
                  class="inline-flex items-center px-2 py-1.5 text-xs font-medium rounded text-gray-500 hover:text-gray-700 hover:bg-gray-100 focus:outline-none">
            #{icon(:more_vertical)}
          </button>
          <div data-dropdown-target="menu"
               class="hidden absolute right-0 z-10 mt-1 w-40 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none">
            <div class="py-1">
              <a href="#{edit_admin_partner_path(record)}#calendars"
                 class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                Calendars
              </a>
              <a href="#{edit_admin_partner_path(record)}#users"
                 class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                Admin Users
              </a>
            </div>
          </div>
        </div>
      </div>
    HTML
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
