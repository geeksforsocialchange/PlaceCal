# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id            :bigint           not null, primary key
#  article_image :string
#  body          :text             not null
#  body_html     :string
#  is_draft      :boolean          default(TRUE), not null
#  published_at  :datetime
#  slug          :string
#  title         :text             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  author_id     :bigint           not null
#
# Indexes
#
#  index_articles_on_author_id     (author_id)
#  index_articles_on_published_at  (published_at)
#  index_articles_on_slug          (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#
class Article < ApplicationRecord
  # ==== Includes / Extends ====
  extend FriendlyId
  include HtmlRenderCache

  # ==== Attributes ====
  # article_image -- managed by CarrierWave, attribute declaration skipped
  attribute :body,         :text
  attribute :body_html,    :string # populated by HtmlRenderCache
  attribute :is_draft,     :boolean, default: true
  attribute :published_at, :datetime
  attribute :slug,         :string
  attribute :title,        :text

  friendly_id :slug_candidates, use: :slugged
  html_render_cache :body

  # ==== Associations ====
  has_many :article_partners, dependent: :destroy
  has_many :partners, through: :article_partners

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags

  belongs_to :author, class_name: 'User', inverse_of: :articles

  # ==== Uploaders ====
  mount_uploader :article_image, ArticleImageUploader

  # ==== Validations ====
  validates :title, :body, presence: true
  validates :slug, uniqueness: true

  # ==== Scopes ====
  scope :published, -> { where is_draft: false }
  scope :by_publish_date, -> { order(published_at: :desc) }

  scope :for_partner, lambda { |partner|
    joins(:article_partners).where(article_partners: { partner_id: partner.id })
  }

  scope :global_newsfeed, -> { published.order(published_at: :desc) }

  scope :with_partner_tag, lambda { |tag_id|
    joins('left outer join article_partners on articles.id=article_partners.article_id')
      .joins('left outer join partner_tags on article_partners.partner_id = partner_tags.partner_id')
      .where('partner_tags.tag_id = ?', tag_id)
  }

  scope :with_tags, lambda { |tag_ids|
    joins(:article_tags).where(article_tags: { tag: tag_ids })
  }

  # Published articles visible on a site: an article is visible iff at least
  # one of its partners is on the site (per PartnersQuery — address OR service
  # area in the site's neighbourhoods, strict partnership-tag filter on tagged
  # sites, hidden partners excluded). News follows the partner, exactly like
  # events. Article tags play no part in site visibility — they remain a
  # curation tool for the tag-based GraphQL queries.
  scope :for_site, lambda { |site|
    site_partners = PartnersQuery.new(site: site).call.reorder(nil)

    published
      .joins(:partners)
      .where(partners: { id: site_partners.select(:id) })
      .distinct
  }

  # ==== Callbacks ====
  before_save :update_published_at, if: ->(obj) { obj.is_draft_changed? }

  # ==== Instance methods ====

  # @return [String] author's full name, or empty string if unset
  def author_name
    author&.full_name ? author.full_name : ''
  end

  # @return [String, nil] high-resolution header image URL
  def highres_image
    article_image&.highres&.url
  end

  # Image for social-share cards: the article's own image, falling back to the
  # first partner's. Callers fall through to the site/directory default when nil.
  #
  # @return [String, nil] image path
  def og_image_path
    return highres_image if article_image.present?

    partner_with_image = partners.detect(&:image?)
    partner_with_image&.image&.url(:standard)
  end

  # @return [Array] FriendlyId slug candidates
  def slug_candidates
    [%i[title id]]
  end

  private

  # ==== Private methods ====
  def update_published_at
    self.published_at = is_draft ? nil : Time.current
  end
end
