class PartnerPublishedAttributeSetValue < ActiveRecord::Migration[6.1]
  def change
    Partner.where(published: nil).update_all(published: true)
  end
end
