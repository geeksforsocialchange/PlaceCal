# frozen_string_literal: true

class Tag < ApplicationRecord
  self.table_name = 'tags'

  has_and_belongs_to_many :users
  has_and_belongs_to_many :partners

  validates :name, :slug, presence: true
  validates :name, :slug, uniqueness: true

  after_save :update_users

  private

  def update_users
    users.each(&:update_role)
  end
end
