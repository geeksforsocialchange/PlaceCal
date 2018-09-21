# frozen_string_literal: true

class Turf < ApplicationRecord
  self.table_name = 'turfs'

  has_and_belongs_to_many :users
  has_and_belongs_to_many :partners
  has_and_belongs_to_many :places

  validates :name, :slug, presence: true
  validates :name, :slug, uniqueness: true

  after_save :update_users

  private

  def update_users
    users.each(&:update_role)
  end
end
