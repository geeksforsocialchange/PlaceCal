# frozen_string_literal: true

class AddContactEmailToSites < ActiveRecord::Migration[8.0]
  def change
    add_column :sites, :contact_email, :string
  end
end
