# frozen_string_literal: true

class SiteDatatable < Datatable
  def view_columns
    @view_columns ||= {
      name: { source: 'Site.name', cond: :like, searchable: true },
      place_name: { source: 'Site.place_name', cond: :like, searchable: true, orderable: true },
      partners_count: { source: 'Site.partners_count', searchable: false, orderable: true },
      events_count: { source: 'Site.events_count', searchable: false, orderable: true },
      site_admin: { source: 'Site.site_admin_id', searchable: false, orderable: false },
      updated_at: { source: 'Site.updated_at', searchable: false, orderable: true },
      actions: { source: 'Site.id', searchable: false, orderable: false }
    }
  end

  def data
    records.map do |record|
      {
        name: render_name_cell(record),
        place_name: render_place_name_cell(record),
        partners_count: render_count_cell(record.partners_count, 'partner'),
        events_count: render_count_cell(record.events_count, 'event'),
        site_admin: render_site_admin_cell(record),
        updated_at: render_relative_time(record.updated_at),
        actions: render_actions(record)
      }
    end
  end

  def get_raw_records
    # Use includes for eager loading, but NOT left_joins which causes duplicates
    # when sites have multiple neighbourhoods
    records = options[:sites]
              .includes(:neighbourhoods, :site_admin)
              .distinct

    # Apply filters from request params
    if params[:filter].present?
      # Has neighbourhoods filter
      if params[:filter][:has_neighbourhoods].present?
        if params[:filter][:has_neighbourhoods] == 'yes'
          records = records.joins(:neighbourhoods).distinct
        elsif params[:filter][:has_neighbourhoods] == 'no'
          records = records.where.missing(:neighbourhoods).distinct
        end
      end

      # Site admin filter by user ID
      records = records.where(site_admin_id: params[:filter][:site_admin_id]) if params[:filter][:site_admin_id].present?
    end

    records
  end

  private

  def records_key
    :sites
  end

  def edit_path_for(record)
    edit_admin_site_path(record)
  end

  def render_name_cell(record)
    url_display = <<~URL_HTML
      <a href="#{ERB::Util.html_escape(record.public_url)}" target="_blank" class="text-xs text-gray-500 font-mono hover:text-orange-600 flex items-center gap-1">
        #{ERB::Util.html_escape(record.display_url)}
        #{icon(:external_link, size: '3')}
      </a>
      #{render_domain_status(record)}
    URL_HTML

    <<~HTML.html_safe # rubocop:disable Rails/OutputSafety
      <div class="flex flex-col gap-0.5">
        <a href="#{edit_admin_site_path(record)}" class="font-medium text-gray-900 hover:text-orange-600">
          #{ERB::Util.html_escape(record.name)}
        </a>
        #{url_display}
      </div>
    HTML
  end

  def render_domain_status(record)
    return '' if record.domain.blank?

    status = record.served_domain? ? I18n.t('admin.sites.domain_status.served') : I18n.t('admin.sites.domain_status.external')
    "<span class=\"text-xs text-gray-500\">#{ERB::Util.html_escape(status)}</span>"
  end

  def render_place_name_cell(record)
    return empty_cell if record.place_name.blank?

    "<span class=\"text-gray-600\">#{ERB::Util.html_escape(record.place_name)}</span>".html_safe # rubocop:disable Rails/OutputSafety
  end

  def render_count_cell(count, label)
    if count.positive?
      <<~HTML.html_safe # rubocop:disable Rails/OutputSafety
        <span class="inline-flex items-center text-emerald-600" title="#{count} #{label}#{'s' if count != 1}">
          #{icon(:check)}
          <span class="ml-1 text-xs">#{count}</span>
        </span>
      HTML
    else
      <<~HTML.html_safe # rubocop:disable Rails/OutputSafety
        <span class="inline-flex items-center text-gray-500" title="No #{label}s">
          #{icon(:x)}
        </span>
      HTML
    end
  end

  def render_site_admin_cell(record)
    admin = record.site_admin
    return empty_cell unless admin

    <<~HTML.html_safe # rubocop:disable Rails/OutputSafety
      <button type="button"
              class="text-left text-gray-600 hover:text-orange-600 hover:underline cursor-pointer"
              data-action="click->admin-table#filterByValue"
              data-filter-column="site_admin_id"
              data-filter-value="#{admin.id}"
              title="Filter by #{ERB::Util.html_escape([admin.first_name, admin.last_name].compact.join(' '))}">
        #{ERB::Util.html_escape([admin.first_name, admin.last_name].compact.join(' '))}
      </button>
    HTML
  end
end
