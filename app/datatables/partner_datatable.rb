class PartnerDatatable < Datatable
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id:         { source: 'Partner.id', cond: :eq },
      name:       { source: 'Partner.name', cond: :like },
      slug:       { source: 'Partner.slug' },
      address:    { source: 'Partner.address', searchable: false },
      updated_at: { source: 'Partner.address' },
    }
  end

  def data
    records.map do |record|
      {
        id:         link_to(record.id,   edit_admin_partner_path(record)),
        name:       link_to(record.name, edit_admin_partner_path(record)),
        slug:       link_to(record.slug, edit_admin_partner_path(record)),
        address:    record.address,
        updated_at: record.updated_at
      }
    end
  end

  def get_raw_records
    # insert query here
    # Partner.all
    options[:partners]
  end
end
