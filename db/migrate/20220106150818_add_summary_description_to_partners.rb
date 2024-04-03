# frozen_string_literal: true

class AddSummaryDescriptionToPartners < ActiveRecord::Migration[6.1]
  def up
    add_column :partners, :summary, :string
    add_column :partners, :description, :text

    remove_column :partners, :short_description, :text
  end

  def down; end
end
