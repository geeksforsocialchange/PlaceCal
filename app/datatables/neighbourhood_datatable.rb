# frozen_string_literal: true

class NeighbourhoodDatatable < Datatable
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id: { source: 'Neighbourhood.id', cond: :eq },
      name: { source: 'Neighbourhood.name' },
      unit_name: { source: 'Neighbourhood.unit_name' },
      unit_code_key: { source: 'Neighbourhood.unit_code_key' },
      unit_code_value: { source: 'Neighbourhood.unit_code_value' },
      parent_name: { source: 'Neighbourhood.parent_name' },
      release_date: { source: 'Neighbourhood.release_date' }
    }
  end

  def data
    records.map do |record|
      {
        id: options[:current_user].can_view_neighbourhood_by_id?(record.id) ? link_to(record.id, admin_neighbourhood_path(record)) : record.id,
        name: record.name,
        unit_name: record.unit_name,
        unit_code_key: record.unit_code_key,
        unit_code_value: record.unit_code_value,
        parent_name: record.parent_name,
        release_date: record.release_date
      }
    end
  end

  def get_raw_records
    # insert query here
    # Neighbourhood.all
    options[:neighbourhoods]
  end
end
