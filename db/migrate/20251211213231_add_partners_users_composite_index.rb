# frozen_string_literal: true

class AddPartnersUsersCompositeIndex < ActiveRecord::Migration[7.2]
  def change
    # Add composite unique index for join table lookups
    # Remove single-column indexes as the composite index covers those queries
    remove_index :partners_users, :partner_id, name: 'index_partners_users_on_partner_id'
    remove_index :partners_users, :user_id, name: 'index_partners_users_on_user_id'

    add_index :partners_users, %i[partner_id user_id],
              unique: true,
              name: 'index_partners_users_partner_id_user_id'
    add_index :partners_users, %i[user_id partner_id],
              name: 'index_partners_users_user_id_partner_id'
  end
end
