# frozen_string_literal: true

class AddTagsIdPartnerTagsTagIdFk < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :partner_tags, :tags, column: :tag_id, primary_key: :id
  end
end
