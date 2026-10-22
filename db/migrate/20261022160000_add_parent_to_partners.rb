# frozen_string_literal: true

class AddParentToPartners < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :partners, :parent, index: { algorithm: :concurrently }
    add_foreign_key :partners, :partners, column: :parent_id, validate: false
  end
end
