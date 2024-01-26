class PartnerUnpublishedReason < ActiveRecord::Migration[6.1]
  def change
    add_column :partners, :unpublished_reason, :string
  end
end
