# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
class UserDatatable < Datatable
  extend Forwardable

  # Override to ensure draw is included
  def as_json(*)
    result = super
    result[:draw] = params[:draw].to_i if params[:draw].present?
    result
  end

  def view_columns
    # NOTE: name searchable is false because we override filter_records to search
    # across first_name, last_name, and email
    @view_columns ||= {
      name: { source: 'User.last_name', cond: :like, searchable: false, orderable: true },
      roles: { source: 'User.role', searchable: false, orderable: false },
      last_sign_in_at: { source: 'User.last_sign_in_at', searchable: false, orderable: true },
      updated_at: { source: 'User.updated_at', searchable: false, orderable: true },
      actions: { source: 'User.id', searchable: false, orderable: false }
    }
  end

  def data
    records.map do |record|
      row_data = {
        name: render_name_cell(record),
        roles: render_roles_cell(record),
        last_sign_in_at: render_relative_time(record.last_sign_in_at),
        updated_at: render_relative_time(record.updated_at),
        actions: render_actions(record)
      }

      # Add row styling for elevated roles (inline style for reliability)
      case record.role.to_s
      when 'root'
        row_data[:DT_RowAttr] = { style: 'background-color: #fef2f2;' }
      when 'editor'
        row_data[:DT_RowAttr] = { style: 'background-color: #eff6ff;' }
      end

      row_data
    end
  end

  # Override to search across first_name, last_name, and email
  def filter_records(records)
    filtered = super

    # Apply search across name fields if there's a search term
    search_value = params.dig(:search, :value)
    if search_value.present?
      search_term = "%#{search_value}%"
      filtered = filtered.where(
        "users.first_name ILIKE :term OR users.last_name ILIKE :term OR users.email ILIKE :term OR CONCAT(users.first_name, ' ', users.last_name) ILIKE :term",
        term: search_term
      )
    end

    filtered
  end

  def get_raw_records
    # Use includes for eager loading, but NOT left_joins which causes duplicates
    # when users have multiple partners/neighbourhoods
    records = options[:users]
              .includes(:partners, :neighbourhoods, :tags)
              .distinct

    # Apply filters from request params
    if params[:filter].present?
      # Role filter
      records = records.where(role: params[:filter][:role]) if params[:filter][:role].present?

      # Has partners filter
      if params[:filter][:has_partners].present?
        if params[:filter][:has_partners] == 'yes'
          records = records.joins(:partners).distinct
        elsif params[:filter][:has_partners] == 'no'
          records = records.where.missing(:partners).distinct
        end
      end

      # Has neighbourhoods filter
      if params[:filter][:has_neighbourhoods].present?
        if params[:filter][:has_neighbourhoods] == 'yes'
          records = records.joins(:neighbourhoods).distinct
        elsif params[:filter][:has_neighbourhoods] == 'no'
          records = records.where.missing(:neighbourhoods).distinct
        end
      end

      # Site admin filter
      if params[:filter][:is_site_admin].present?
        if params[:filter][:is_site_admin] == 'yes'
          records = records.where(id: Site.where.not(site_admin_id: nil).select(:site_admin_id))
        elsif params[:filter][:is_site_admin] == 'no'
          records = records.where.not(id: Site.where.not(site_admin_id: nil).select(:site_admin_id))
        end
      end
    end

    records
  end

  def records_total_count
    options[:users].count
  end

  def records_filtered_count
    filter_records(get_raw_records).except(:limit, :offset, :order).count
  end

  # Override to put NULL last_sign_in_at values at the bottom
  def sort_records(records)
    sort_by = datatable.orders.first
    return records unless sort_by

    column_name = sort_by.column.source
    direction = sort_by.direction

    # For last_sign_in_at, put NULLs at the bottom regardless of sort direction
    if column_name == 'User.last_sign_in_at'
      nulls_position = direction == 'desc' ? 'NULLS LAST' : 'NULLS FIRST'
      records.order(Arel.sql("users.last_sign_in_at #{direction.upcase} #{nulls_position}"))
    else
      super
    end
  end

  private

  def render_name_cell(record)
    full_name = [record.first_name, record.last_name].compact.join(' ').presence

    name_html = if full_name
                  "<a href=\"#{edit_admin_user_path(record)}\" class=\"font-medium text-gray-900 hover:text-orange-600\">#{ERB::Util.html_escape(full_name)}</a>"
                else
                  "<a href=\"#{edit_admin_user_path(record)}\" class=\"italic text-gray-400 hover:text-orange-600\">No name</a>"
                end

    <<~HTML.html_safe
      <div class="flex flex-col">
        #{name_html}
        <span class="text-xs text-gray-400 font-mono"><i class="fa fa-hashtag mr-1"></i>#{record.id} <i class="fa fa-envelope mr-1"></i>#{ERB::Util.html_escape(record.email)}</span>
      </div>
    HTML
  end

  def render_roles_cell(record)
    roles = []

    # Primary role badge
    case record.role.to_s
    when 'root'
      roles << '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800">Root</span>'
    when 'editor'
      roles << '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">Editor</span>'
    end

    # Admin type badges
    roles << '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800">Partner Admin</span>' if record.partner_admin?
    roles << '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-indigo-100 text-indigo-800">Neighbourhood Admin</span>' if record.neighbourhood_admin?
    roles << '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-teal-100 text-teal-800">Partnership Admin</span>' if record.partnership_admin?
    roles << '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-amber-100 text-amber-800">Site Admin</span>' if record.site_admin?

    return '<span class="text-gray-400">—</span>'.html_safe if roles.empty?

    <<~HTML.html_safe
      <div class="flex flex-wrap gap-1">
        #{roles.join("\n")}
      </div>
    HTML
  end

  def render_relative_time(datetime)
    return '<span class="text-gray-400">—</span>'.html_safe unless datetime

    days_ago = (Time.current - datetime).to_i / 1.day

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
      relative = datetime.strftime('%-d %b %Y')
    end

    <<~HTML.html_safe
      <span class="text-gray-500 text-sm whitespace-nowrap" title="#{datetime.strftime('%d %b %Y at %H:%M')}">#{relative}</span>
    HTML
  end

  def render_actions(record)
    <<~HTML.html_safe
      <div class="flex items-center gap-2">
        <a href="#{edit_admin_user_path(record)}"
           class="inline-flex items-center px-2.5 py-1.5 text-xs font-medium rounded text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500">
          Edit
        </a>
      </div>
    HTML
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
