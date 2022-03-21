# frozen_string_literal: true

class Article < ApplicationRecord
  validates :title, :body, presence: true

  has_many :article_partners
  has_many :partners, through: :article_partners

  scope :published, -> { where is_draft: false }
  scope :by_publish_date, -> { order(:published_at) }

end
