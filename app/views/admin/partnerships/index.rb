# frozen_string_literal: true

class Views::Admin::Partnerships::Index < Views::Admin::Base
  prop :partnerships, _Any, reader: :private
  prop :admin_options, _Any, reader: :private

  def view_template
    render Components::Admin::Datatable.new(
      title: 'Partnerships',
      model: :partnerships,
      column_titles: ['Partnership', 'Admins', 'Partners', 'Last Updated', ''],
      columns: %i[name admins_count partners_count updated_at actions],
      column_config: {
        name: {},
        admins_count: { sortable: false },
        partners_count: { align: :center, sortable: false, fit: true },
        updated_at: { fit: true },
        actions: { sortable: false, fit: true }
      },
      default_sort: { column: 'updated_at', direction: 'desc' },
      filters: [
        { column: 'admin_id', label: 'Admin', width: 'w-48', tom_select: true,
          options: admin_options },
        { column: 'has_partners', label: 'Partners', width: 'w-36',
          options: [{ value: 'yes', label: 'Has partners' }, { value: 'no', label: 'No partners' }] }
      ],
      data: partnerships,
      source: admin_partnerships_path(format: :json),
      new_link: (new_admin_partnership_path if view_context.policy(Partnership).create?)
    )
  end
end
