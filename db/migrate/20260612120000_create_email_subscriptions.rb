# frozen_string_literal: true

class CreateEmailSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :email_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :list_key, null: false
      t.boolean :subscribed, null: false
      t.string :source, null: false

      t.timestamps
    end
    add_index :email_subscriptions, %i[user_id list_key], unique: true

    create_table :email_subscription_events do |t|
      t.references :user, null: false, foreign_key: true
      t.string :list_key, null: false
      t.boolean :old_subscribed
      t.boolean :new_subscribed, null: false
      t.string :source, null: false
      t.references :actor, foreign_key: { to_table: :users }

      t.datetime :created_at, null: false
    end
  end
end
