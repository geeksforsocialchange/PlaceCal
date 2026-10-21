# frozen_string_literal: true

class AddDomainToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :domain, :string
    # Site ignores url from now on, so inserts must not need it.
    change_column_null :sites, :url, true
  end
end
