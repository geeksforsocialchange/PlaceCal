# frozen_string_literal: true

class CreateSupporters < ActiveRecord::Migration[5.1]
  def change
    create_table :supporters do |t|
      t.string :name
      t.string :url
      t.string :logo
      t.string :description
      t.integer :weight

      t.timestamps
    end
  end
end
