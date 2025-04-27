# frozen_string_literal: true

class ChangeServiceAreasNeighbourhoodIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :service_areas, :neighbourhood_id, false
  end
end
