# frozen_string_literal: true

class ChangeDomainToUrl < ActiveRecord::Migration[6.1]
  def self.up
    rename_column :sites, :domain, :url
  end

  def self.down
    rename_column :sites, :url, :domain
  end
end
