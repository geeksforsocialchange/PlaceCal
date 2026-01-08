# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
class PartnerDatatable < Datatable
  extend Forwardable

  def_delegator :@view, :admin_partner_calendars_path
  def_delegator :@view, :admin_partner_users_path

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
              .group('partners.id, ward_neighbourhoods.name')

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

      # District filter - filter by all wards within a district
      if params[:filter][:district].present?
        district = Neighbourhood.find_by(id: params[:filter][:district])
        if district
          ward_ids = district.descendants.where(unit: 'ward').pluck(:id)
          records = records.where(ward_neighbourhoods: { id: ward_ids })
        end
      end

      # Ward/neighbourhood filter
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

  # Override count methods to handle GROUP BY correctly
  # When using GROUP BY, count returns a hash, so we need to count the keys
  def records_total_count
    # Total count should be all partners in the base scope (before any filters)
    options[:partners].count
  end

  def records_filtered_count
    # Filtered count includes our custom filters AND the DataTables search
    # We need to keep HAVING clauses since calendar/admin filters use them
    records = filter_records(fetch_records).unscope(:limit, :offset, :order)

    # Count using a subquery to preserve GROUP BY and HAVING
    subquery = records.except(:select).select('partners.id')
    Partner.from(subquery, :partners).count
  end

  private

  def render_name_cell(record)
    <<~HTML.html_safe
      <div class="flex flex-col">
        <a href="#{edit_admin_partner_path(record)}" class="font-medium text-gray-900 hover:text-orange-600">
          #{ERB::Util.html_escape(record.name)}
        </a>
        <span class="text-xs text-gray-400 font-mono"><i class="fa fa-hashtag"></i>#{record.id}</span>
      </div>
    HTML
  end

  def render_ward_cell(record)
    neighbourhood = record.address&.neighbourhood
    neighbourhood ||= record.service_areas.first&.neighbourhood if record.service_areas.any?

    if neighbourhood
      name = neighbourhood.shortname
      display_name = name.length > 20 ? "#{name[0..18]}…" : name

      <<~HTML.html_safe
        <button type="button"
                class="text-gray-600 hover:text-orange-600 hover:underline cursor-pointer text-left"
                data-action="click->admin-table#filterByValue"
                data-filter-column="ward"
                data-filter-value="#{neighbourhood.id}"
                title="Filter by #{ERB::Util.html_escape(name)}">
          #{ERB::Util.html_escape(display_name)}
        </button>
      HTML
    else
      <<~HTML.html_safe
        <span class="text-gray-400">—</span>
      HTML
    end
  end

  def render_calendar_status(record, count)
    calendars = record.calendars

    if calendars.empty?
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-400" title="No calendars">
          #{cross_icon}
        </span>
      HTML
    else
      # Check for any calendars with errors
      error_calendars = calendars.select { |c| c.calendar_state.to_s.in?(%w[error bad_source]) }

      if error_calendars.any?
        <<~HTML.html_safe
          <span class="inline-flex items-center text-red-600" title="#{error_calendars.size} calendar#{'s' if error_calendars.size != 1} with errors">
            #{error_icon}
          </span>
        HTML
      else
        <<~HTML.html_safe
          <span class="inline-flex items-center text-emerald-600" title="#{count} calendar#{'s' if count != 1} connected">
            #{check_icon}
          </span>
        HTML
      end
    end
  end

  def render_tick_cross(has_items, title_yes, title_no)
    if has_items
      <<~HTML.html_safe
        <span class="inline-flex items-center text-emerald-600" title="#{title_yes}">
          #{check_icon}
        </span>
      HTML
    else
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-400" title="#{title_no}">
          #{cross_icon}
        </span>
      HTML
    end
  end

  def render_partnerships(partnerships)
    if partnerships.empty?
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-400" title="No partnerships">
          #{cross_icon}
        </span>
      HTML
    else
      # Create clickable buttons for each partnership
      buttons = partnerships.map do |p|
        name = p.name
        display_name = name.length > 25 ? "#{name[0..23]}…" : name

        <<~BUTTON
          <button type="button"
                  class="text-gray-700 hover:text-orange-600 hover:underline cursor-pointer"
                  data-action="click->admin-table#filterByValue"
                  data-filter-column="partnership"
                  data-filter-value="#{p.id}"
                  title="Filter by #{ERB::Util.html_escape(name)}">#{ERB::Util.html_escape(display_name)}</button>
        BUTTON
      end

      separator = partnerships.size >= 2 ? '<br>' : ', '
      <<~HTML.html_safe
        <span class="text-sm">
          #{buttons.join(separator)}
        </span>
      HTML
    end
  end

  def render_updated_at(record)
    date = record.updated_at
    return '—' unless date

    # Show relative time for recent updates, absolute for older
    days_ago = (Time.current - date).to_i / 1.day

    if days_ago.zero?
      relative = 'Today'
    elsif days_ago == 1
      relative = 'Yesterday'
    elsif days_ago < 7
      relative = "#{days_ago} days ago"
    elsif days_ago < 30
      weeks = days_ago / 7
      relative = "#{weeks} week#{'s' if weeks != 1} ago"
    else
      relative = date.strftime('%-d %b %Y')
    end

    <<~HTML.html_safe
      <span class="text-gray-500 text-sm whitespace-nowrap" title="#{date.strftime('%d %b %Y at %H:%M')}">#{relative}</span>
    HTML
  end

  def render_date(date)
    return '—' unless date

    <<~HTML.html_safe
      <span class="text-gray-500 text-sm">#{date.strftime('%d %b %Y')}</span>
    HTML
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
            #{more_icon}
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

  def calendar_icon
    '<svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>'
  end

  def user_icon
    '<svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>'
  end

  def more_icon
    '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"></path></svg>'
  end

  def check_icon
    '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>'
  end

  def error_icon
    '<svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>'
  end

  def cross_icon
    '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>'
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
