# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
class SiteDatatable < Datatable
  def view_columns
    @view_columns ||= {
      name: { source: 'Site.name', cond: :like, searchable: true },
      neighbourhoods: { source: 'Site.id', searchable: false, orderable: false },
      site_admin: { source: 'Site.site_admin_id', searchable: false, orderable: false },
      updated_at: { source: 'Site.updated_at', searchable: false, orderable: true },
      actions: { source: 'Site.id', searchable: false, orderable: false }
    }
  end

  def data
    records.map do |record|
      neighbourhoods_count = record.neighbourhoods.size

      {
        name: render_name_cell(record),
        neighbourhoods: render_count_cell(neighbourhoods_count, 'neighbourhood'),
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

      # Has site admin filter
      if params[:filter][:has_admin].present?
        if params[:filter][:has_admin] == 'yes'
          records = records.where.not(site_admin_id: nil)
        elsif params[:filter][:has_admin] == 'no'
          records = records.where(site_admin_id: nil)
        end
      end
    end

    records
  end

  def records_total_count
    options[:sites].count
  end

  def records_filtered_count
    filter_records(get_raw_records).except(:limit, :offset, :order).count
  end

  private

  def render_name_cell(record)
    <<~HTML.html_safe
      <div class="flex flex-col">
        <a href="#{edit_admin_site_path(record)}" class="font-medium text-gray-900 hover:text-orange-600">
          #{ERB::Util.html_escape(record.name)}
        </a>
        <span class="text-xs text-gray-400 font-mono">##{record.id} · /#{ERB::Util.html_escape(record.slug)}</span>
      </div>
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
      <span class="text-gray-600">#{ERB::Util.html_escape([admin.first_name, admin.last_name].compact.join(' '))}</span>
    HTML
  end

  def render_actions(record)
    <<~HTML.html_safe
      <div class="flex items-center gap-2">
        <a href="#{edit_admin_site_path(record)}"
           class="inline-flex items-center px-2.5 py-1.5 text-xs font-medium rounded text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-orange-500">
          Edit
        </a>
      </div>
    HTML
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/AbcSize, Rails/OutputSafety
