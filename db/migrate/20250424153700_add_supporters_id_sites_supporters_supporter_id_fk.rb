# frozen_string_literal: true

class AddSupportersIdSitesSupportersSupporterIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :sites_supporters, :supporters, column: :supporter_id, primary_key: :id
  end
end
