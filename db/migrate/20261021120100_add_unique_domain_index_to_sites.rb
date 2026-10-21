# frozen_string_literal: true

class AddUniqueDomainIndexToSites < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :sites, :domain, unique: true, where: 'domain IS NOT NULL', algorithm: :concurrently
  end
end
