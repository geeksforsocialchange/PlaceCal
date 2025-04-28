# frozen_string_literal: true

class AddPartnersLowerNameIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :partners, 'lower(name)', name: :index_partners_lower_name_, unique: true
  end
end
