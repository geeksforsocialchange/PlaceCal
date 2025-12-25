# frozen_string_literal: true

class ChangeServiceAreasPartnerIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :service_areas, :partner_id, false
  end
end
