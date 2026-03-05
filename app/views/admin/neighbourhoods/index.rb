# frozen_string_literal: true

class Views::Admin::Neighbourhoods::Index < Views::Admin::Base
  register_value_helper :safe_neighbourhood_name

  prop :neighbourhoods, ActiveRecord::Relation, reader: :private

  def view_template
    Datatable(
      title: t('admin.neighbourhoods.index.title'),
      model: :neighbourhoods,
      column_titles: [
        t('admin.neighbourhoods.index.columns.neighbourhood'),
        t('admin.neighbourhoods.index.columns.level'),
        t('admin.neighbourhoods.index.columns.hierarchy'),
        t('admin.neighbourhoods.index.columns.partners'),
        t('admin.neighbourhoods.index.columns.release'),
        ''
      ],
      columns: %i[name unit hierarchy partners_count release_date actions],
      column_config: {
        name: {},
        unit: { fit: true },
        hierarchy: { sortable: false },
        partners_count: { fit: true },
        release_date: { fit: true, sortable: false },
        actions: { sortable: false, fit: true }
      },
      default_sort: { column: 'partners_count', direction: 'desc' },
      filters: neighbourhoods_filters,
      secondary_filters: neighbourhoods_secondary_filters,
      data: neighbourhoods,
      source: admin_neighbourhoods_path(format: :json)
    )

    render_roots_section
    render_ons_release
  end

  private

  def neighbourhoods_filters
    [
      { column: 'unit', label: t('admin.neighbourhoods.index.columns.level'), width: 'w-32',
        options: %w[ward district county region country].map do |u|
          { value: u, label: t("admin.neighbourhoods.index.levels.#{u}") }
        end },
      { column: 'release', label: t('admin.neighbourhoods.index.columns.release'), width: 'w-32',
        default: 'current',
        options: [{ value: 'current', label: t('admin.neighbourhoods.index.release.current') },
                  { value: 'legacy', label: t('admin.neighbourhoods.index.release.legacy') }] }
    ]
  end

  def neighbourhoods_secondary_filters
    country_options = Neighbourhood.countries.latest_release.order(:name).map do |n|
      { value: n.id, label: n.name }
    end
    endpoint = children_admin_neighbourhoods_path(format: :json)

    [
      { column: 'country_id', label: t('admin.neighbourhoods.index.levels.country'), width: 'min-w-40',
        type: :hierarchical, level: 5, endpoint: endpoint, options: country_options },
      { column: 'region_id', label: t('admin.neighbourhoods.index.levels.region'), width: 'min-w-48',
        type: :hierarchical, level: 4, parent_filter: 'country_id', endpoint: endpoint },
      { column: 'county_id', label: t('admin.neighbourhoods.index.levels.county'), width: 'min-w-48',
        type: :hierarchical, level: 3, parent_filter: 'region_id', endpoint: endpoint },
      { column: 'district_id', label: t('admin.neighbourhoods.index.levels.district'), width: 'min-w-48',
        type: :hierarchical, level: 2, parent_filter: 'county_id', endpoint: endpoint }
    ]
  end

  def render_roots_section
    h2(class: 'text-xl font-semibold text-gray-900 mt-8 mb-4') { t('admin.neighbourhoods.index.roots_title') }

    div(class: 'bg-white shadow-sm rounded-lg p-4') do
      Neighbourhood.roots.order(:name).each do |root|
        p(class: 'mb-2') do
          link_to safe_neighbourhood_name(root), admin_neighbourhood_path(root),
                  class: 'text-placecal-orange-dark hover:underline'
        end
      end
    end
  end

  def render_ons_release
    p(class: 'text-sm text-gray-500 mt-4') do
      plain t('admin.neighbourhoods.index.ons_release', date: Neighbourhood::LATEST_RELEASE_DATE)
    end
  end
end
