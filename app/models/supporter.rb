# frozen_string_literal: true

# == Schema Information
#
# Table name: supporters
#
#  id          :bigint           not null, primary key
#  description :string
#  is_global   :boolean          default(FALSE), not null
#  logo        :string
#  name        :string           not null
#  url         :string
#  weight      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Supporter < ApplicationRecord
  # ==== Attributes ====
  attribute :description, :string
  attribute :is_global,   :boolean, default: false
  # logo -- managed by CarrierWave, attribute declaration skipped
  attribute :name,        :string
  attribute :url,         :string
  attribute :weight,      :integer

  # ==== Associations ====
  has_many :sites_supporters, dependent: :destroy
  has_and_belongs_to_many :sites

  # ==== Uploaders ====
  mount_uploader :logo, SupporterLogoUploader

  # ==== Validations ====
  validates :name, presence: true

  # ==== Scopes ====
  default_scope { order(:weight) }
  scope :global, -> { where(is_global: true) }
end
