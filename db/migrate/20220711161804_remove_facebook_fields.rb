class RemoveFacebookFields < ActiveRecord::Migration[6.1]
  def change
    remove_column :partners, :facebook_link
    remove_column :users, :facebook_app_id
    remove_column :users, :facebook_app_secret
  end
end
