class TagDatatable < Datatable
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id: { source: 'Tag.id', cond: :eq },
      name: { source: 'Tag.name' },
      slug: { source: 'Tag.slug' },
      description: { source: 'Tag.description' },
      edit_permission: { source: 'Tag.edit_permission' }
    }
  end

  def data
    records.map do |record|
      {
        id: link_to(record.id, edit_admin_tag_path(record)),
        name: link_to(record.name, edit_admin_tag_path(record)),
        slug: record.slug,
        description: record.description,
        edit_permission: record.edit_permission
      }
    end
  end

  def get_raw_records
    # insert query here
    # Tag.all
    options[:tags]
  end
end
