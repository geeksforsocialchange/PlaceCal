# frozen_string_literal: true

class Views::Admin::Sites::Index < Views::Admin::Base
  register_value_helper :icon_column_header

  prop :sites, ActiveRecord::Relation, reader: :private
  prop :site_admin_options, Array, reader: :private

  def view_template
    Datatable(
      title: 'Sites',
      model: :sites,
      column_titles: [
        'Site', 'Neighbourhood',
        icon_column_header(:partner, 'Partners'),
        icon_column_header(:calendar, 'Events'),
        'Site Admin', 'Last Updated', ''
      ],
      columns: %i[name primary_neighbourhood partners_count events_count site_admin updated_at actions],
      column_config: {
        name: {},
        primary_neighbourhood: { sortable: false },
        partners_count: { align: :center, fit: true, sort_default: 'desc' },
        events_count: { align: :center, fit: true, sort_default: 'desc' },
        site_admin: { sortable: false },
        updated_at: { fit: true },
        actions: { sortable: false, fit: true }
      },
      default_sort: { column: 'updated_at', direction: 'desc' },
      filters: [
        { column: 'has_neighbourhoods', label: 'Neighbourhoods', width: 'w-40',
          options: [{ value: 'yes', label: 'Has neighbourhoods' },
                    { value: 'no', label: 'No neighbourhoods' }] },
        { column: 'site_admin_id', label: 'Site Admin', width: 'w-48', tom_select: true,
          options: site_admin_options }
      ],
      data: sites,
      source: admin_sites_path(format: :json),
      new_link: new_admin_site_path
    )
  end
end
