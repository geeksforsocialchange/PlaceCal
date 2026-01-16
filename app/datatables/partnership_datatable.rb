# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
class PartnershipDatatable < Datatable
  def view_columns
    @view_columns ||= {
      name: { source: 'Partnership.name', cond: :like, searchable: true },
      admins_count: { source: 'Partnership.id', searchable: false, orderable: false },
      partners_count: { source: 'Partnership.id', searchable: false, orderable: false },
      updated_at: { source: 'Partnership.updated_at', searchable: false, orderable: true },
      actions: { source: 'Partnership.id', searchable: false, orderable: false }
    }
  end

  def data
    records.map do |record|
      {
        name: render_name_cell(record),
        admins_count: render_admins_cell(record),
        partners_count: render_count_cell(record.partners.size, 'partner'),
        updated_at: render_relative_time(record.updated_at),
        actions: render_actions(record)
      }
    end
  end

  def get_raw_records
    records = options[:partnerships]
              .includes(:partners, :users)
              .distinct

    # Apply filters from request params
    if params[:filter].present?
      # System tag filter
      if params[:filter][:system_tag].present?
        if params[:filter][:system_tag] == 'yes'
          records = records.where(system_tag: true)
        elsif params[:filter][:system_tag] == 'no'
          records = records.where(system_tag: false)
        end
      end

      # Has partners filter
      if params[:filter][:has_partners].present?
        if params[:filter][:has_partners] == 'yes'
          records = records.joins(:partners).distinct
        elsif params[:filter][:has_partners] == 'no'
          records = records.where.missing(:partners).distinct
        end
      end

      # Admin filter
      records = records.joins(:users).where(users: { id: params[:filter][:admin_id] }).distinct if params[:filter][:admin_id].present?
    end

    records
  end

  private

  def records_key
    :partnerships
  end

  def edit_path_for(record)
    edit_admin_partnership_path(record)
  end

  def render_name_cell(record)
    <<~HTML.html_safe
      <div class="flex flex-col">
        <a href="#{edit_admin_partnership_path(record)}" class="font-medium text-gray-900 hover:text-orange-600">
          #{ERB::Util.html_escape(record.name)}
        </a>
        <span class="text-xs text-gray-500 font-mono">##{record.id} · #{ERB::Util.html_escape(record.slug)}</span>
      </div>
    HTML
  end

  def render_description_cell(record)
    return '<span class="text-gray-500">—</span>'.html_safe if record.description.blank?

    truncated = record.description.truncate(50)
    tooltip = ERB::Util.html_escape(record.description)

    <<~HTML.html_safe
      <span class="text-gray-600 text-sm" title="#{tooltip}">
        #{ERB::Util.html_escape(truncated)}
      </span>
    HTML
  end

  def render_system_tag_cell(record)
    if record.system_tag?
      <<~HTML.html_safe
        <span class="inline-flex items-center text-amber-700" title="System tag">
          #{icon(:lock)}
        </span>
      HTML
    else
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-300" title="User-created">
          #{icon(:unlock)}
        </span>
      HTML
    end
  end

  def render_admins_cell(record)
    admins = record.users
    count = admins.size

    return <<~HTML.html_safe if count.zero?
      <span class="inline-flex items-center text-gray-500" title="No admins">
        #{icon(:x)}
      </span>
    HTML

    links = admins.first(2).map do |user|
      name = [user.first_name, user.last_name].compact.join(' ')
      name = user.email.split('@').first if name.blank?
      "<a href=\"#{edit_admin_user_path(user)}\" class=\"text-gray-700 hover:text-orange-600\">#{ERB::Util.html_escape(name)}</a>"
    end

    if count <= 2
      <<~HTML.html_safe
        <span class="text-sm">#{links.join(', ')}</span>
      HTML
    else
      remaining = count - 2
      <<~HTML.html_safe
        <span class="text-sm">
          #{links.join(', ')}
          <a href="#{edit_admin_partnership_path(record)}" class="text-gray-500 hover:text-orange-600">
            and #{remaining} more...
          </a>
        </span>
      HTML
    end
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
