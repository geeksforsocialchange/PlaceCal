# frozen_string_literal: true

class AddFacebookAppIdAndFacebookAppSecretToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :facebook_app_id, :text
    add_column :users, :facebook_app_secret, :text
  end
end
