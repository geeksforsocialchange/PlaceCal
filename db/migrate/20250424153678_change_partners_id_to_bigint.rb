# frozen_string_literal: true

class ChangePartnersIdToBigint < ActiveRecord::Migration[7.2]
  def up
    change_column :partners, :id, :bigint
  end

  def down
    change_column :partners, :id, :integer
  end
end
