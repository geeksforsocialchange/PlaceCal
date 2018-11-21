class AddSocialMediaColumnsToPartners < ActiveRecord::Migration[5.1]
  def change
    add_column :partners, :twitter_handle, :string
    add_column :partners, :facebook_link, :string
  end
end
