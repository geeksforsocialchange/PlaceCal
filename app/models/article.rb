# frozen_string_literal: true

class Article < ApplicationRecord
  validates :title, :body, presence: true

  before_save :update_published_at, if: ->(obj) { obj.is_draft_changed? }

  has_many :article_partners, dependent: :destroy
  has_many :partners, through: :article_partners

  scope :published, -> { where is_draft: false }
  scope :by_publish_date, -> { order(:published_at) }

  scope :global_newsfeed, -> { published.order(published_at: :desc) }

  def update_published_at
    self.published_at = self.is_draft ? nil : DateTime.now
  end
end
