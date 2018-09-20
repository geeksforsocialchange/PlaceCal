# frozen_string_literal: true

class Neighbourhood < ApplicationRecord
  self.table_name = 'neighbourhoods'

  class << self
    def create_from_admin_ward admin_ward
      t = Neighbourhood.new
      t.name = admin_ward
      # t.slug = admin_ward.downcase.gsub(/ /, "-")
      t.save && t
    end
  end
end
