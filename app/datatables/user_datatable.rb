class UserDatatable < Datatable
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id:          { source: 'User.id', cond: :eq },
      first_name:  { source: 'User.first_name' },
      last_name:   { source: 'User.last_name' },
      admin_roles: { source: 'User.admin_roles', searchable: false, orderable: false },
      email:       { source: 'User.email' },
      updated_at:  { source: 'User.updated_at' }
    }
  end

  def data
    records.map do |record|
      {
        id:          link_to(record.id, edit_admin_user_path(record)),
        first_name:  link_to(record.first_name, edit_admin_user_path(record)),
        last_name:   link_to(record.last_name, edit_admin_user_path(record)),
        admin_roles: record.admin_roles,
        email:       record.email,
        updated_at:  record.updated_at
      }
    end
  end

  def get_raw_records
    # insert query here
    # User.all
    options[:users]
  end
end
