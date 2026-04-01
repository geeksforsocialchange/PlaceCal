# frozen_string_literal: true

class Article < ApplicationRecord
  # -- Includes / Extends --
  extend FriendlyId
  include HtmlRenderCache

  # -- Attributes --
  # article_image -- managed by CarrierWave, attribute declaration skipped
  attribute :body,         :text
  attribute :body_html,    :string # populated by HtmlRenderCache
  attribute :is_draft,     :boolean, default: true
  attribute :published_at, :date
  attribute :slug,         :string
  attribute :title,        :text

  friendly_id :slug_candidates, use: :slugged
  html_render_cache :body

  # -- Associations --
  has_many :article_partners, dependent: :destroy
  has_many :partners, through: :article_partners

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags

  belongs_to :author, class_name: 'User', inverse_of: :articles

  # -- Uploaders --
  mount_uploader :article_image, ArticleImageUploader

  # -- Validations --
  validates :title, :body, presence: true
  validates :slug, uniqueness: true

  # -- Scopes --
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
    # this is a bit complicated but necessary
    # the main problem to overcome is that we want articles by tag OR location
    # (emphasis on OR).
    #
    # in simple AR land we would just chain scope methods like
    #   `Article.by_tag(tags).by_location(neighbourhoods)` and be done with it
    # each scope would set up its `joins` to pull in tables and its `wheres`
    # to filter based on those joins. simple!
    # but unfortunately these scopes get combined with 'AND' clauses in
    # the `where` part.
    #
    # so what this does is build up the query for tags and locations like
    # we were chaining scope methods without the conditions. we store
    # the conditions as (clause, params) in an array as we go. when we reach
    # the end we then extend the scope with a `where` clause that combines
    # everything with `OR' as is needed and then return that to the
    # calling code as a regular scope for further chaining.
    #
    # this also also allows us to skip an entire chunk of query if the
    # site has no tags or locations.

    site_neighbourhood_ids = site.owned_neighbourhoods.pluck(:id)
    site_tag_ids = site.tags.pluck(:id)

    # if site has no tags or neighbourhoods then just return nothing to caller
    return none if site_neighbourhood_ids.empty? && site_tag_ids.empty?

    scope = all

    where_fragments = []
    where_params = []

    # articles by neighbourhood
    if site_neighbourhood_ids.any?
      # TODO: service areas?
      scope = scope
              .joins('LEFT OUTER JOIN article_partners ON articles.id=article_partners.article_id')
              .joins('LEFT OUTER JOIN partners ON article_partners.partner_id = partners.id')
              .joins('LEFT OUTER JOIN addresses ON partners.address_id = addresses.id')
      where_fragments << 'addresses.neighbourhood_id IN (?)'
      where_params << site_neighbourhood_ids
    end

    # articles by tag
    if site_tag_ids.any?
      scope = scope
              .joins(' LEFT OUTER JOIN article_tags ON articles.id=article_tags.article_id')
      where_fragments << 'article_tags.tag_id IN (?)'
      where_params << site_tag_ids
    end

    # combine conditions with params to extend the scope
    scope = scope
            .where("(#{where_fragments.join(' OR ')})", *where_params)

    scope.distinct('articles.id')
  }

  # -- Callbacks --
  before_save :update_published_at, if: ->(obj) { obj.is_draft_changed? }

  # -- Instance methods --

  # @return [String] author's full name, or empty string if unset
  def author_name
    author&.full_name ? author.full_name : ''
  end

  # @return [String, nil] high-resolution header image URL
  def highres_image
    article_image&.highres&.url
  end

  # @return [Array] FriendlyId slug candidates
  def slug_candidates
    [%i[title id]]
  end

  private

  # -- Private methods --
  def update_published_at
    self.published_at = is_draft ? nil : DateTime.now
  end
end
