# frozen_string_literal: true

class AddDefaultFalseToIsAPlaceInPartners < ActiveRecord::Migration[7.2]
  def change
    change_column_default :partners, :is_a_place, from: nil, to: false
  end
end
