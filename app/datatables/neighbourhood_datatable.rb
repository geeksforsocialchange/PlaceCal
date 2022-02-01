class NeighbourhoodDatatable < Datatable
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id:              { source: 'Neighbourhood.id', cond: :eq },
      name:            { source: 'Neighbourhood.name' },
      unit_name:       { source: 'Neighbourhood.unit_name' },
      unit_code_key:   { source: 'Neighbourhood.unit_code_key' },
      unit_code_value: { source: 'Neighbourhood.unit_code_value' },
      parent_name:     { source: 'Neighbourhood.parent_name' },
    }
  end

  def data
    records.map do |record|
      {
        id:              link_to(record.id, edit_admin_neighbourhood_path(record)),
        name:            record.name,
        unit_name:       record.unit_name,
        unit_code_key:   record.unit_code_key,
        unit_code_value: record.unit_code_value,
        parent_name:     record.parent_name,
      }
    end
  end

  def get_raw_records
    # insert query here
    # Neighbourhood.all
    options[:neighbourhoods]
  end
end
