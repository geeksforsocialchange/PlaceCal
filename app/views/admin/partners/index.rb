# frozen_string_literal: true

class Views::Admin::Partners::Index < Views::Admin::Base
  register_value_helper :icon_column_header

  prop :partners, ActiveRecord::Relation, reader: :private
  prop :partnership_options, Array, reader: :private
  prop :category_options, Array, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render Components::Admin::Datatable.new(
      title: 'Partners',
      model: :partners,
      column_titles: [
        'Partner', 'Neighbourhood', 'Partnerships',
        icon_column_header(:calendar, 'Calendars'),
        icon_column_header(:users, 'Admins'),
        icon_column_header(:tag, 'Categories'),
        'Last Updated', ''
      ],
      columns: %i[name ward partnerships calendars admins categories updated_at actions],
      column_config: {
        name: {},
        ward: { sortable: false },
        partnerships: { sortable: false },
        calendars: { align: :center, sortable: false, fit: true },
        admins: { align: :center, sortable: false, fit: true },
        categories: { align: :center, sortable: false, fit: true },
        updated_at: { fit: true },
        actions: { sortable: false, fit: true }
      },
      default_sort: { column: 'updated_at', direction: 'desc' },
      filters: partners_filters,
      secondary_filters: partners_secondary_filters,
      data: partners,
      source: admin_partners_path(format: :json),
      new_link: new_admin_partner_path
    )
  end

  private

  def partners_filters
    [
      { column: 'partnership', label: 'Partnership', tom_select: true, width: 'w-48',
        options: partnership_options },
      { type: :radio, column: 'calendar_status', label: t('admin.partners.filters.has_calendar'),
        options: [{ value: 'connected', label: t('admin.labels.yes') },
                  { value: 'none', label: t('admin.labels.no') }] },
      { type: :radio, column: 'has_admins', label: t('admin.partners.filters.has_admin'),
        options: [{ value: 'yes', label: t('admin.labels.yes') },
                  { value: 'no', label: t('admin.labels.no') }] }
    ]
  end

  def partners_secondary_filters # rubocop:disable Metrics/MethodLength
    [
      { column: 'category', label: 'Category', width: 'w-40', options: category_options },
      { column: 'country_id', label: 'Country (L5)', width: 'min-w-40', type: :hierarchical, level: 5,
        endpoint: children_admin_neighbourhoods_path(format: :json),
        options: Neighbourhood.countries.latest_release.order(:name).map { |n| { value: n.id, label: n.name } } },
      { column: 'region_id', label: 'Region (L4)', width: 'min-w-48', type: :hierarchical, level: 4,
        parent_filter: 'country_id', endpoint: children_admin_neighbourhoods_path(format: :json) },
      { column: 'county_id', label: 'County (L3)', width: 'min-w-48', type: :hierarchical, level: 3,
        parent_filter: 'region_id', endpoint: children_admin_neighbourhoods_path(format: :json) },
      { column: 'district_id', label: 'District (L2)', width: 'min-w-48', type: :hierarchical, level: 2,
        parent_filter: 'county_id', endpoint: children_admin_neighbourhoods_path(format: :json) },
      { column: 'ward_id', label: 'Ward (L1)', width: 'min-w-48', type: :hierarchical, level: 1,
        parent_filter: 'district_id', endpoint: children_admin_neighbourhoods_path(format: :json) }
    ]
  end
end
