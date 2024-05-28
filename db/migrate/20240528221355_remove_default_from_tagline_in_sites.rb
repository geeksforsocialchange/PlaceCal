# frozen_string_literal: true

class RemoveDefaultFromTaglineInSites < ActiveRecord::Migration[7.1]
  def change
    change_column_default :sites, :tagline, from: 'The Community Calendar', to: nil
  end
end
