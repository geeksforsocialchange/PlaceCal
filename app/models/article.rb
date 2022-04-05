# frozen_string_literal: true

class Article < ApplicationRecord
  validates :title, :body, presence: true

  before_save :update_published_at, if: ->(obj) { obj.is_draft_changed? }

  has_many :article_partners, dependent: :destroy
  has_many :partners, through: :article_partners

  belongs_to :author, class_name: 'User'

  mount_uploader :article_image, ArticleHeaderUploader

  scope :published, -> { where is_draft: false }
  scope :by_publish_date, -> { order(:published_at) }

  scope :global_newsfeed, -> { published.order(published_at: :desc) }

  def update_published_at
    self.published_at = self.is_draft ? nil : DateTime.now
  end

  # This retrieves the author's name for use in the GQL output
  # We return emptystring because that indicates to the user that this field is required
  def author_name
    author&.full_name ? author.full_name : ''
  end

  # This retrieves the url of the highres header image for use in GQL output
  # We let it return nil because articles are not guaranteed to have images
  def highres_image
    article_image&.highres&.url
  end
end
