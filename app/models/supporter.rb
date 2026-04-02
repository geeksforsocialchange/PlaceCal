# frozen_string_literal: true

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
