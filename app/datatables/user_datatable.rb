class UserDatatable < AjaxDatatablesRails::ActiveRecord

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id:          { source: 'User.id', cond: :eq },
      first_name:  { source: 'User.first_name' },
      last_name:   { source: 'User.last_name' },
      admin_roles: { source: 'User.admin_roles' },
      email:       { source: 'User.email' },
    }
  end

  def data
    records.map do |record|
      {
        id:          record.id,
        first_name:  record.first_name,
        last_name:   record.last_name,
        admin_roles: record.admin_roles,
        email:       record.email
      }
    end
  end

  def get_raw_records
    # insert query here
    # User.all
    options[:users]
  end
end
