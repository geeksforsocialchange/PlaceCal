# frozen_string_literal: true

class ValidatePartnersParentForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :partners, column: :parent_id
  end
end
