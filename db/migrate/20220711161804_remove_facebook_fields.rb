class RemoveFacebookFields < ActiveRecord::Migration[6.1]
  def change
    remove_column :partners, :facebook_link, :string
    remove_column :users, :facebook_app_id, :text
    remove_column :users, :facebook_app_secret, :text
  end
end
