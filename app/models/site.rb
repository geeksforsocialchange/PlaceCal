# frozen_string_literal: true

# == Schema Information
#
# Table name: sites
#
#  id                :bigint           not null, primary key
#  badge_zoom_level  :string
#  contact_email     :string
#  description       :text
#  description_html  :string
#  events_count      :integer          default(0), not null
#  footer_logo       :string
#  hero_alttext      :string
#  hero_image        :string
#  hero_image_credit :string
#  hero_text         :string
#  is_published      :boolean          default(FALSE), not null
#  logo              :string
#  name              :string           not null
#  partners_count    :integer          default(0), not null
#  place_name        :string
#  slug              :string           not null
#  tagline           :string
#  theme             :string           default("pink")
#  url               :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  site_admin_id     :bigint
#
# Indexes
#
#  index_sites_is_published       (is_published)
#  index_sites_on_events_count    (events_count)
#  index_sites_on_partners_count  (partners_count)
#  index_sites_slug               (slug) UNIQUE
#  index_sites_url                (url)
#
# Foreign Keys
#
#  fk_rails_...  (site_admin_id => users.id)
#
class Site < ApplicationRecord
  # ==== Includes / Extends ====
  extend FriendlyId
  extend Enumerize
  include HtmlRenderCache
  include SiteJsonLd
  include SiteRobots
  include SlugRetainable

  # ==== Constants ====

  # ASSUMPTION: There is no row in the sites table for the admin site, hence
  # defining the admin subdomain string here.
  ADMIN_SUBDOMAIN = 'admin'

  # Canonical apex URL for the nationwide directory. The directory has no Site
  # row — an apex request resolves to no site and renders the directory.
  # Resolved in config/initializers/directory_url.rb (the environment's
  # own apex URL; test pins the production URL).
  DIRECTORY_URL = Rails.configuration.x.directory_url

  # ==== Enums / Enumerize ====
  # theme -- no enumerize: validated against the extension registry below (#3368, D2)
  enumerize :badge_zoom_level,
            in: %i[ward district],
            default: :ward
  # badge_zoom_level -- managed by enumerize, attribute declaration skipped

  # ==== Attributes ====
  # Columns marked (nullable) have no NOT NULL constraint in the DB.
  attribute :contact_email,     :string                          # nullable
  attribute :description,       :text                            # nullable
  attribute :description_html,  :string                          # nullable, populated by HtmlRenderCache
  attribute :events_count,      :integer, default: 0             # NOT NULL
  attribute :hero_alttext,      :string                          # nullable
  attribute :hero_image_credit, :string                          # nullable
  attribute :hero_text,         :string                          # nullable
  attribute :is_published,      :boolean, default: false         # NOT NULL
  # logo, footer_logo, hero_image -- managed by CarrierWave, attribute declarations skipped
  attribute :name,              :string                          # NOT NULL
  attribute :partners_count,    :integer, default: 0             # NOT NULL
  attribute :place_name,        :string                          # nullable
  attribute :slug,              :string                          # NOT NULL
  attribute :tagline,           :string                          # nullable
  attribute :theme,             :string,  default: 'pink'        # nullable
  attribute :url,               :string                          # NOT NULL

  friendly_id :name, use: :slugged
  html_render_cache :description

  # ==== Associations ====
  has_one :sites_neighbourhood, dependent: :destroy
  has_one :primary_neighbourhood, lambda {
                                    where(sites_neighbourhoods: { relation_type: 'Primary' })
                                  }, source: :neighbourhood, through: :sites_neighbourhood

  has_many :sites_neighbourhoods, dependent: :destroy
  has_many :secondary_neighbourhoods, lambda {
                                        where(sites_neighbourhoods: { relation_type: 'Secondary' })
                                      }, source: :neighbourhood, through: :sites_neighbourhoods

  has_many :neighbourhoods, through: :sites_neighbourhoods

  has_many :sites_tag, dependent: :destroy
  has_many :tags, through: :sites_tag

  has_many :sites_supporters, dependent: :destroy
  has_and_belongs_to_many :supporters

  belongs_to :site_admin, class_name: 'User', inverse_of: :sites, optional: true

  accepts_nested_attributes_for :sites_neighbourhood
  accepts_nested_attributes_for :sites_neighbourhoods, reject_if: lambda { |c|
                                                                    c[:neighbourhood_id].blank?
                                                                  }, allow_destroy: true

  # ==== Uploaders ====
  mount_uploader :logo, SiteLogoUploader
  mount_uploader :footer_logo, SiteLogoUploader
  mount_uploader :hero_image, HeroImageUploader

  # ==== Validations ====
  validates :name, :slug, :url, presence: true
  validates :slug, uniqueness: true
  validates :hero_text, length: { maximum: 120 }
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  # Themes come from the extension registry, not a static list, so an
  # extension can add one without touching this model (#3368, D2).
  # allow_blank keeps the enumerize-era behaviour where a site could carry no
  # theme at all and render core's default styling (#3368).
  validates :theme, inclusion: { in: ->(_site) { PlaceCal::Extensions.theme_names } }, allow_blank: true

  # ==== Scopes ====
  scope :published, -> { where(is_published: true) }

  # ==== Instance methods ====

  def to_s
    "#{id}: #{name}"
  end

  # Where this site's Join ("get in touch") enquiries are sent. Sites without
  # their own address fall back to the PlaceCal support inbox (#3368, D13).
  #
  # @return [String]
  def join_recipient
    contact_email.presence || Join::DEFAULT_RECIPIENT
  end

  # The site's public URL, falling back to its conventional placecal.org
  # subdomain when no explicit url is set.
  #
  # @return [String]
  def directory_url
    url.presence || "https://#{slug}.placecal.org"
  end

  # @return [String] directory_url without the scheme or trailing slash, for display
  def display_url
    directory_url.sub(%r{\Ahttps?://}, '').chomp('/')
  end

  # @return [Boolean] whether FriendlyId should generate a new slug
  # Regenerates from the name whenever the slug is blank (e.g. left empty on
  # the new-site form), mirroring Partner so the slug auto-populates on create.
  def should_generate_new_friendly_id?
    slug.blank?
  end

  # @return [Array<Neighbourhood>] all neighbourhoods in this site's subtrees
  def owned_neighbourhoods
    neighbourhoods.map(&:subtree).flatten
  end

  # @return [Array<Integer>] all neighbourhood IDs in this site's subtrees
  def owned_neighbourhood_ids
    neighbourhoods
      .select(:id, :ancestry)
      .map(&:subtree_ids)
      .flatten
  end

  # Whether a site shows News in its nav is derived from this count (#3368 D6),
  # so every page of every site runs it. Memoised per instance for the request
  # and cached across requests for ten minutes.
  #
  # There is no cheap invalidation hook: an Article belongs to a site only
  # indirectly, through its partners and tags (Article.for_site), so saving one
  # article can change the count for any number of sites. Rather than sweep
  # every site on every article save, the count goes stale for at most the TTL,
  # which only ever means a News link appearing or leaving the nav a few
  # minutes late.
  #
  # @return [Integer] published articles count for this site
  def news_article_count
    @news_article_count ||= Rails.cache.fetch(['site', id, 'news_article_count'], expires_in: 10.minutes) do
      Article.for_site(self).published.count
    end
  end

  # @return [Boolean] whether neighbourhood badges should be shown
  def show_neighbourhoods?
    owned_neighbourhood_ids.many?
  end

  # @return [String] "near" for multi-neighbourhood sites, "in" otherwise
  def join_word
    if owned_neighbourhoods.many?
      'near'
    else
      'in'
    end
  end

  # @return [EventsQuery]
  def events_query
    EventsQuery.new(site: self)
  end

  # @return [Integer] number of events starting this week
  def events_this_week
    events_query.count_for_period('week')
  end

  # @return [Integer] number of events that started last week
  def events_last_week
    EventsQuery.new(site: self, day: Time.zone.today - 1.week).count_for_period('week')
  end

  # @return [void]
  def refresh_partners_count!
    return unless persisted?

    count = PartnersQuery.new(site: self).call.count
    update_column(:partners_count, count) # rubocop:disable Rails/SkipsModelValidations
  end

  # @return [void]
  def refresh_events_count!
    return unless persisted?

    count = events_query.count_for_period('week')
    update_column(:events_count, count) # rubocop:disable Rails/SkipsModelValidations
  end

  # @return [void]
  def refresh_counts!
    refresh_partners_count!
    refresh_events_count!
  end

  # @return [String, nil] asset pipeline stylesheet path for this site's theme,
  #   or nil when no stylesheet should be linked. Any theme whose stylesheet is
  #   missing from the pipeline resolves to nil, so the page renders with the
  #   default styling instead of raising Propshaft::MissingAssetError
  #   (#2936, #3368).
  def stylesheet_link
    PlaceCal::Theme.for(self).stylesheet_for(self)
  end

  # @return [String, false] Open Graph image URL, or false
  def og_image
    hero_image&.opengraph&.url ? hero_image.opengraph.url : false
  end

  # @return [String, false] tagline for OG description, or false
  def og_description
    tagline && tagline.empty? ? false : tagline
  end

  # ==== Class methods ====

  class << self
    # @param value [Array] enumerize value pair
    # @return [String] titleized label
    def badge_zoom_level_label(value)
      value.second.to_s.titleize
    end

    # Refresh cached counts for all sites.
    # @return [void]
    def refresh_all_counts!
      find_each(&:refresh_counts!)
    end

    # Find any sites with URLs that match the specified domain
    #
    # [QAD 2025-10-21] This a band-aid to work around the implementation in
    # https://github.com/geeksforsocialchange/PlaceCal/pull/2201 which removed
    # the site.domain field in favour of a site.url field. Long-term, a better
    # implementation would be to restore site.domain and reverse the implementation
    # of the above PR.
    def find_using_domain(domain)
      # Should be no need to sanitize `domain` because the interpolation happens
      # before it is passed to Arel for sanitization
      find_by(url: ["https://#{domain}", "https://#{domain}/"])
    end

    # Find the requested Site from information in the rails request object.
    #
    # @param request The request must expose the methods: host, subdomain, subdomains
    # @return [Site, nil] nil for the apex / no-subdomain request (the
    #   nationwide directory has no Site row)
    def find_by_request(request)
      # If there is a site with the domain in request.host, return it
      site = find_using_domain(request.host)
      return site if site.present?

      site_slug =
        if request.subdomain == 'www'
          request.subdomains.second if request&.subdomains&.second
        elsif request.subdomain.present?
          request.subdomain
        end

      return if site_slug.blank?

      Site.find_by(slug: site_slug)
    end

    # Get a list of Sites where the given partner would appear.
    #
    # Mirrors PartnersQuery#build_base_scope: a site scopes its partners by its
    # neighbourhoods, by its tags, or by both (tag AND neighbourhood). A tagged
    # site with no neighbourhoods is tag-only, so a partnership site such as
    # The Trans Dimension contains every partner carrying one of its tags
    # wherever that partner lives (#3368 D7, D24).
    #
    # @param partner [Partner]
    # @return [Array<Site>]
    def sites_that_contain_partner(partner)
      neighbourhood_site_ids = site_ids_covering_partner_neighbourhoods(partner)
      tag_site_ids = SitesTag.where(tag_id: partner.tag_ids).distinct.pluck(:site_id)

      candidate_ids = neighbourhood_site_ids | tag_site_ids
      return [] if candidate_ids.empty?

      # Only published sites are live on the public directory, so a partner can
      # only "appear" on a published site.
      sites = Site.published
                  .where(id: candidate_ids)
                  .includes(:tags, :neighbourhoods)
                  .order(:name)

      sites.select do |site|
        tagged = site.tags.any?
        placed = site.neighbourhoods.any?

        next false unless tagged || placed
        next false if tagged && tag_site_ids.exclude?(site.id)
        next false if placed && neighbourhood_site_ids.exclude?(site.id)

        true
      end
    end

    private

    # Sites with at least one neighbourhood covering the partner's address or
    # service areas. A partner's neighbourhood is in a site's subtree when the
    # site's neighbourhood is an ancestor of (or equal to) the partner's.
    #
    # @param partner [Partner]
    # @return [Array<Integer>] site ids
    def site_ids_covering_partner_neighbourhoods(partner)
      partner_neighbourhood_ids = []
      partner_neighbourhood_ids << partner.address.neighbourhood_id if partner.address&.neighbourhood_id
      partner_neighbourhood_ids += partner.service_areas.pluck(:neighbourhood_id)
      partner_neighbourhood_ids.uniq!

      return [] if partner_neighbourhood_ids.empty?

      matching_neighbourhood_ids = Neighbourhood.where(id: partner_neighbourhood_ids)
                                                .flat_map(&:path_ids)
                                                .uniq

      return [] if matching_neighbourhood_ids.empty?

      SitesNeighbourhood.where(neighbourhood_id: matching_neighbourhood_ids)
                        .distinct
                        .pluck(:site_id)
    end
  end
end
