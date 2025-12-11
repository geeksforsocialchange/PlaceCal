# frozen_string_literal: true

class AddPartnersHiddenIndex < ActiveRecord::Migration[7.2]
  def change
    # Index for filtering visible partners (scope :visible)
    add_index :partners, :hidden, name: 'index_partners_hidden'
  end
end
