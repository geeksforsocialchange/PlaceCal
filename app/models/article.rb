# frozen_string_literal: true

class Article < ApplicationRecord
  extend FriendlyId

  include HtmlRenderCache
  html_render_cache :body

  friendly_id :slug_candidates, use: :slugged

  validates :title, :body, presence: true

  before_save :update_published_at, if: ->(obj) { obj.is_draft_changed? }

  has_many :article_partners, dependent: :destroy
  has_many :partners, through: :article_partners

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags

  belongs_to :author, class_name: 'User'

  mount_uploader :article_image, ArticleImageUploader

  scope :published, -> { where is_draft: false }
  scope :by_publish_date, -> { order(published_at: :desc) }

  scope :global_newsfeed, -> { published.order(published_at: :desc) }

  scope :with_partner_tag, lambda { |tag_id|
    joins('left outer join article_partners on articles.id=article_partners.article_id')
    .joins('left outer join partner_tags on article_partners.partner_id = partner_tags.partner_id')
    .where('partner_tags.tag_id = ?', tag_id)
  }

  scope :with_tags, lambda { |tag_ids|
    joins(:article_tags).where(article_tags: { tag: tag_ids })
  }

  scope :for_site, lambda { |site|
    scope = all

    site_neighbourhood_ids = site.owned_neighbourhoods.pluck(:id)
    site_tag_ids = site.tags.pluck(:id)
    return scope if site_neighbourhood_ids.empty? && site_tag_ids.empty?

    where_fragments = []
    where_params = []

    # articles by neighbourhood
    if site_neighbourhood_ids.any?
      scope = scope
        .joins('left outer join article_partners on articles.id=article_partners.article_id')
        .joins('left outer join partners on article_partners.partner_id = partners.id')
        .joins('left outer join addresses on partners.address_id = addresses.id')
      where_fragments << 'addresses.neighbourhood_id in (?)'
      where_params << site_neighbourhood_ids
    end

    # articles by tag
    if site_tag_ids.any?
      scope = scope
        .joins(' LEFT OUTER JOIN article_tags ON articles.id=article_tags.article_id')
      where_fragments << 'article_tags.tag_id in (?)'
      where_params << site_tag_ids
    end

    scope = scope
      .where("(#{where_fragments.join(' OR ')})", *where_params)

    scope.distinct('articles.id')
  }

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

  def slug_candidates
   [ %i[title id] ]
  end
end
