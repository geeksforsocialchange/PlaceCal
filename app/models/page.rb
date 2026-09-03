# frozen_string_literal: true

# A static content page belonging to a Site (#3368, D5).
#
# Partnerships need their own About/Privacy style copy. Rather than shipping
# site-specific views, the content lives in the database and is edited in admin
# by the site's own admin. Pages are served at the top level (`/about`) to match
# PlaceCal's existing URL convention for static pages (D14).
# == Schema Information
#
# Table name: pages
#
#  id           :bigint           not null, primary key
#  body         :text
#  body_html    :text
#  is_published :boolean          default(FALSE), not null
#  position     :integer          default(0), not null
#  show_in_nav  :boolean          default(FALSE), not null
#  slug         :string           not null
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  site_id      :bigint           not null
#
# Indexes
#
#  index_pages_on_site_id_and_slug  (site_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (site_id => sites.id)
#
class Page < ApplicationRecord
  # ==== Includes / Extends ====
  include HtmlRenderCache

  # ==== Constants ====

  # Path prefixes that are served outside the Rails router (Propshaft/Sprockets
  # and friends), so they never appear in `Rails.application.routes` but would
  # still shadow a page.
  NON_ROUTED_RESERVED_SLUGS = %w[assets packs manifest].freeze

  # `privacy` is deliberately allowed even though core routes `/privacy`.
  # PagesController#privacy prefers a site's own published `privacy` page and
  # only falls back to the directory markdown, so a partnership can supply its
  # own privacy copy at the conventional URL (D14). No other core route is
  # overridable this way.
  OVERRIDABLE_ROUTE_SLUGS = %w[privacy].freeze

  # ==== Attributes ====
  attribute :body,         :text
  attribute :body_html,    :text # populated by HtmlRenderCache
  attribute :is_published, :boolean, default: false
  attribute :position,     :integer, default: 0
  attribute :show_in_nav,  :boolean, default: false
  attribute :slug,         :string
  attribute :title,        :string

  html_render_cache :body

  # ==== Associations ====
  belongs_to :site

  # ==== Validations ====
  validates :title, presence: true
  validates :slug, presence: true,
                   format: { with: /\A[a-z0-9-]+\z/, message: :invalid_page_slug },
                   uniqueness: { scope: :site_id }
  validate :slug_is_not_reserved

  # ==== Scopes ====
  scope :published, -> { where(is_published: true) }
  scope :in_nav, -> { published.where(show_in_nav: true).order(:position, :title) }

  class << self
    # Slugs a page may not claim, because a core route already owns that first
    # path segment. Derived from the router so new core routes are covered
    # automatically. Memoised: the route set does not change at runtime.
    #
    # @return [Array<String>]
    def reserved_slugs
      @reserved_slugs ||= begin
        routed = Rails.application.routes.routes.filter_map do |route|
          next if route.constraints[:subdomain] == Site::ADMIN_SUBDOMAIN

          segment = route.path.spec.to_s.split('/')[1].to_s.sub(/\(.*/, '')
          next if segment.blank? || segment.start_with?('*', ':')

          segment.downcase
        end

        (routed + NON_ROUTED_RESERVED_SLUGS - OVERRIDABLE_ROUTE_SLUGS).uniq.sort.freeze
      end
    end

    # Clears the memoised reserved slug list (tests that redraw routes).
    def reset_reserved_slugs!
      @reserved_slugs = nil
    end
  end

  # ==== Instance methods ====

  # @return [String] plain-text lead-in used for meta descriptions
  def summary(limit = 160)
    body.to_s.gsub(/[#*_>`\[\]()]/, ' ').squish.truncate(limit)
  end

  private

  # ==== Private methods ====
  def slug_is_not_reserved
    return if slug.blank?
    return unless self.class.reserved_slugs.include?(slug.downcase)

    errors.add(:slug, :reserved_page_slug)
  end
end
