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
    @view_columns ||= {
      name: { source: 'User.last_name', cond: :like, searchable: true },
      first_name: { source: 'User.first_name', cond: :like, searchable: true },
      email: { source: 'User.email', cond: :like, searchable: true },
      roles: { source: 'User.role', searchable: false, orderable: false },
      partners: { source: 'User.id', searchable: false, orderable: false },
      neighbourhoods: { source: 'User.id', searchable: false, orderable: false },
      updated_at: { source: 'User.updated_at', searchable: false, orderable: true },
      actions: { source: 'User.id', searchable: false, orderable: false }
    }
  end

  def data
    records.map do |record|
      partners_count = record.partners.size
      neighbourhoods_count = record.neighbourhoods.size

      {
        name: render_name_cell(record),
        roles: render_roles_cell(record),
        partners: render_count_cell(partners_count, 'partner'),
        neighbourhoods: render_count_cell(neighbourhoods_count, 'neighbourhood'),
        updated_at: render_relative_time(record.updated_at),
        actions: render_actions(record)
      }
    end
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
    end

    records
  end

  def records_total_count
    options[:users].count
  end

  def records_filtered_count
    filter_records(get_raw_records).except(:limit, :offset, :order).count
  end

  private

  def render_name_cell(record)
    full_name = [record.first_name, record.last_name].compact.join(' ').presence || 'No name'
    <<~HTML.html_safe
      <div class="flex flex-col">
        <a href="#{edit_admin_user_path(record)}" class="font-medium text-gray-900 hover:text-orange-600">
          #{ERB::Util.html_escape(full_name)}
        </a>
        <span class="text-xs text-gray-500">#{ERB::Util.html_escape(record.email)}</span>
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
    when 'citizen'
      roles << '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">Citizen</span>'
    end

    # Admin type badges
    roles << '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800">Partner Admin</span>' if record.partner_admin?
    roles << '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-indigo-100 text-indigo-800">Neighbourhood Admin</span>' if record.neighbourhood_admin?
    roles << '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-teal-100 text-teal-800">Partnership Admin</span>' if record.partnership_admin?
    roles << '<span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-amber-100 text-amber-800">Site Admin</span>' if record.site_admin?

    <<~HTML.html_safe
      <div class="flex flex-wrap gap-1">
        #{roles.join("\n")}
      </div>
    HTML
  end

  def render_count_cell(count, label)
    if count.positive?
      <<~HTML.html_safe
        <span class="inline-flex items-center text-emerald-600" title="#{count} #{label}#{'s' if count != 1}">
          #{check_icon}
          <span class="ml-1 text-xs">#{count}</span>
        </span>
      HTML
    else
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-400" title="No #{label}s">
          #{cross_icon}
        </span>
      HTML
    end
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

  def check_icon
    '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>'
  end

  def cross_icon
    '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>'
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
