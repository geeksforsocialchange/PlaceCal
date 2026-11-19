# frozen_string_literal: true

class AddSocialLinksToPartners < ActiveRecord::Migration[8.1]
  def change
    add_column :partners, :social_links, :jsonb, default: [], null: false
  end
end
