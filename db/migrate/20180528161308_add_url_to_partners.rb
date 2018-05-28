class AddUrlToPartners < ActiveRecord::Migration[5.1]
  def change
    add_column :partners, :url, :string
  end
end
