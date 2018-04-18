class Site < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  validates :name, :slug, :domain, presence: true
  has_and_belongs_to_many :turfs
end
