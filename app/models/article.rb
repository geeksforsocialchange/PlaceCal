# frozen_string_literal: true

class Article < ApplicationRecord
  validates :title, :body, presence: true

  before_save :update_published_at

  has_many :article_partners, dependent: :destroy
  has_many :partners, through: :article_partners

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags

  belongs_to :author, class_name: 'User'

  mount_uploader :article_image, ArticleImageUploader

  scope :published, -> { where is_draft: false }
  scope :by_publish_date, -> { order(:published_at) }

  scope :global_newsfeed, -> { published.order(published_at: :desc) }

  scope :with_tag, ->(tag_id) { joins(:article_tags).where(article_tags: { tag: tag_id }) }

  scope :with_partner_tag, lambda { |tag_id|
    joins('left outer join article_partners on articles.id=article_partners.article_id')
    .joins('left outer join partner_tags on article_partners.partner_id = partner_tags.partner_id')
    .where('partner_tags.tag_id = ?', tag_id)
  }

  def update_published_at
    self.published_at = is_draft ? nil : DateTime.now
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
