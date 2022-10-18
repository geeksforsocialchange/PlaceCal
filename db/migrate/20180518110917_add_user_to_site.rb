# frozen_string_literal: true

class AddUserToSite < ActiveRecord::Migration[5.1]
  def change
    add_reference :sites, :site_admin, foreign_key: { to_table: :users }
  end
end
