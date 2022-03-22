# frozen_string_literal: true

class Article < ApplicationRecord
  validates :title, :body, presence: true

  before_save :update_published_at, if: ->(obj) { obj.is_draft_changed? }

  has_many :article_partners
  has_many :partners, through: :article_partners

  scope :published, -> { where is_draft: false }
  scope :by_publish_date, -> { order(:published_at) }

  def update_published_at
    self.published_at = self.is_draft ? nil : DateTime.now
  end
end
