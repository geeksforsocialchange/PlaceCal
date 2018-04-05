class Turf < ApplicationRecord
  extend Enumerize
  after_create :create_tenant

  enumerize :turf_type, in: %i[interest neighbourhood]

  has_and_belongs_to_many :users
  has_and_belongs_to_many :partners

  validates :name, :slug, presence: true

  private

  def create_tenant
    Aparment::Tenant.create('ggggg')
  end
end
