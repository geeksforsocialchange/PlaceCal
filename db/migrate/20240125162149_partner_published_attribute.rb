class PartnerPublishedAttribute < ActiveRecord::Migration[6.1]
  def change
    add_column :partners, :published, :boolean, default: true
  end
end
