# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
class SiteDatatable < Datatable
  def view_columns
    @view_columns ||= {
      name: { source: 'Site.name', cond: :like, searchable: true },
      primary_neighbourhood: { source: 'Site.id', searchable: false, orderable: false },
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
        primary_neighbourhood: render_primary_neighbourhood_cell(record),
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
              .includes(:neighbourhoods, :primary_neighbourhood, :site_admin)
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
    site_url = record.url.presence
    url_display = if site_url
                    # Show just the domain part for cleaner display
                    domain = site_url.gsub(%r{^https?://}, '').chomp('/')
                    <<~URL_HTML
                      <a href="#{ERB::Util.html_escape(site_url)}" target="_blank" class="text-xs text-gray-400 font-mono hover:text-orange-600 flex items-center gap-1">
                        #{ERB::Util.html_escape(domain)}
                        #{icon(:external_link, size: '3')}
                      </a>
                    URL_HTML
                  else
                    "<span class=\"text-xs text-gray-400 font-mono\">##{record.id} · /#{ERB::Util.html_escape(record.slug)}</span>"
                  end

    <<~HTML.html_safe
      <div class="flex flex-col gap-0.5">
        <a href="#{edit_admin_site_path(record)}" class="font-medium text-gray-900 hover:text-orange-600">
          #{ERB::Util.html_escape(record.name)}
        </a>
        #{url_display}
      </div>
    HTML
  end

  def render_primary_neighbourhood_cell(record)
    neighbourhood = record.primary_neighbourhood
    return empty_cell unless neighbourhood

    <<~HTML.html_safe
      <a href="#{admin_neighbourhood_path(neighbourhood)}" class="text-gray-600 hover:text-orange-600 hover:underline">
        #{ERB::Util.html_escape(neighbourhood.shortname)}
      </a>
    HTML
  end

  def render_count_cell(count, label)
    if count.positive?
      <<~HTML.html_safe
        <span class="inline-flex items-center text-emerald-600" title="#{count} #{label}#{'s' if count != 1}">
          #{icon(:check)}
          <span class="ml-1 text-xs">#{count}</span>
        </span>
      HTML
    else
      <<~HTML.html_safe
        <span class="inline-flex items-center text-gray-400" title="No #{label}s">
          #{icon(:x)}
        </span>
      HTML
    end
  end

  def render_site_admin_cell(record)
    admin = record.site_admin
    return empty_cell unless admin

    <<~HTML.html_safe
      <button type="button"
              class="text-gray-600 hover:text-orange-600 hover:underline cursor-pointer"
              data-action="click->admin-table#filterByValue"
              data-filter-column="site_admin_id"
              data-filter-value="#{admin.id}"
              title="Filter by #{ERB::Util.html_escape([admin.first_name, admin.last_name].compact.join(' '))}">
        #{ERB::Util.html_escape([admin.first_name, admin.last_name].compact.join(' '))}
      </button>
    HTML
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
