class NeighbourhoodDatatable < AjaxDatatablesRails::ActiveRecord
  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id:       { source: 'Neighbourhood.id', cond: :eq },
      name:     { source: 'Neighbourhood.name' },
      county:   { source: 'Neighbourhood.county', orderable: false, searchable: false },
      district: { source: 'Neighbourhood.district', orderable: false, searchable: false },
      region:   { source: 'Neighbourhood.region', orderable: false, searchable: false  },
      country:  { source: 'Neighbourhood.country', orderable: false, searchable: false  }
    }
  end

  def data
    records.map do |record|
      {
        id:       record.id,
        name:     record.name,
        county:   record.county,
        district: record.district,
        region:   record.region,
        country:  record.country
      }
    end
  end

  def get_raw_records
    # insert query here
    # Neighbourhood.all
    options[:neighbourhoods]
  end
end
