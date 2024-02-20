# frozen_string_literal: true

class PartnerHiddenAttributeSetValue < ActiveRecord::Migration[6.1]
  def change
    Partner.where(hidden: nil).update_all(hidden: false)
  end
end
