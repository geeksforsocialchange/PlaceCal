class SiteDatatable < Datatable
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id: {
        source: "Site.id",
        cond: :eq
      },
      name: {
        source: "Site.name"
      },
      slug: {
        source: "Site.slug"
      },
      updated_at: {
        source: "Site.updated_at"
      }
    }
  end

  def data
    records.map do |record|
      {
        id: link_to(record.id, edit_admin_site_path(record)),
        name: link_to(record.name, edit_admin_site_path(record)),
        slug: record.slug,
        updated_at: record.updated_at
      }
    end
  end

  def get_raw_records
    # insert query here
    # User.all
    options[:sites]
  end
end
