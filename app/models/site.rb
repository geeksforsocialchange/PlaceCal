# frozen_string_literal: true

class Site < ApplicationRecord
  extend FriendlyId
  extend Enumerize

  include HtmlRenderCache

  html_render_cache :description

  friendly_id :name, use: :slugged

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

  validates :name, :slug, :url, presence: true
  validates :slug, uniqueness: true
  validates :place_name unless :default_site?
  validates :hero_text, length: { maximum: 120 }

  scope :published, -> { where(is_published: true) }

  mount_uploader :logo, SiteLogoUploader
  mount_uploader :footer_logo, SiteLogoUploader
  mount_uploader :hero_image, HeroImageUploader

  # Theme picker
  enumerize :theme,
            in: %i[pink orange green blue custom],
            default: :pink

  enumerize :badge_zoom_level,
            in: %i[ward district],
            default: :ward

  def to_s
    "#{id}: #{name}"
  end

  def owned_neighbourhoods
    neighbourhoods.map(&:subtree).flatten
  end

  def owned_neighbourhood_ids
    neighbourhoods
      .select(:id, :ancestry)
      .map(&:subtree_ids)
      .flatten
  end

  # ASSUMPTION: There is no row in the sites table for the admin site, hence
  # defining the admin subdomain string here.
  ADMIN_SUBDOMAIN = 'admin'

  def news_article_count
    Article
      .for_site(self)
      .published
      .count
  end

  def default_site?
    slug == 'default-site'
  end

  # ASSUMPTION: All valid sites, other than the default site, are local sites.
  def local_site?
    !default_site?
  end

  # Should we show the neighbourhood lozenge out on this site?
  def show_neighbourhoods?
    owned_neighbourhood_ids.many?
  end

  def self.badge_zoom_level_label(value)
    value.second.to_s.titleize
  end

  def join_word
    if owned_neighbourhoods.many?
      'near'
    else
      'in'
    end
  end

  def events_query
    EventsQuery.new(site: self)
  end

  # Get a count of all the events this week
  def events_this_week
    events_query.count_for_period('week')
  end

  # Get a count of all the events last week
  def events_last_week
    EventsQuery.new(site: self, day: Time.zone.today - 1.week).count_for_period('week')
  end

  # Refresh cached partners_count for this site
  def refresh_partners_count!
    return unless persisted?

    count = PartnersQuery.new(site: self).call.count
    update_column(:partners_count, count) # rubocop:disable Rails/SkipsModelValidations
  end

  # Refresh cached events_count for this site (events this week)
  def refresh_events_count!
    return unless persisted?

    count = events_query.count_for_period('week')
    update_column(:events_count, count) # rubocop:disable Rails/SkipsModelValidations
  end

  # Refresh both cached counts
  def refresh_counts!
    refresh_partners_count!
    refresh_events_count!
  end

  def stylesheet_link
    return 'home' if default_site?

    if theme == :custom
      "themes/custom/#{slug}"
    else
      "themes/#{theme}"
    end
  end

  def og_image
    hero_image&.opengraph&.url ? hero_image.opengraph.url : false
  end

  def og_description
    tagline && tagline.empty? ? false : tagline
  end

  def robots
    config = File.read(Rails.root.join("config/robots/robots.#{Rails.env}.txt"))

    if is_published?
      config
    else
      <<~TXT
        #{config}
        User-agent: *
        Disallow: /
      TXT
    end
  end

  class << self
    # Refresh cached counts for all sites
    # Run periodically or after bulk partner/event changes
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
    # @return [Site]
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

      # No subdomain? Fall back to the default site.
      site_slug ||= 'default-site'

      Site.find_by(slug: site_slug)
    end

    # Get a list of Sites whose neighbourhood subtree and tags
    # match the given partner (i.e. where the partner would appear).
    #
    # @param partner [Partner]
    # @return [Array<Site>]
    def sites_that_contain_partner(partner)
      # Collect all neighbourhood IDs the partner is associated with
      partner_neighbourhood_ids = []
      partner_neighbourhood_ids << partner.address.neighbourhood_id if partner.address&.neighbourhood_id
      partner_neighbourhood_ids += partner.service_areas.pluck(:neighbourhood_id)
      partner_neighbourhood_ids.uniq!

      return [] if partner_neighbourhood_ids.empty?

      # A partner's neighbourhood is in a site's subtree when the site's
      # neighbourhood is an ancestor of (or equal to) the partner's neighbourhood.
      matching_neighbourhood_ids = Neighbourhood.where(id: partner_neighbourhood_ids)
                                                .flat_map(&:path_ids)
                                                .uniq

      return [] if matching_neighbourhood_ids.empty?

      site_ids = SitesNeighbourhood.where(neighbourhood_id: matching_neighbourhood_ids)
                                   .distinct
                                   .pluck(:site_id)

      return [] if site_ids.empty?

      sites = Site.where(id: site_ids).includes(:tags).order(:name)

      # Sites with tags only match if the partner has at least one of those tags
      partner_tag_ids = partner.tag_ids.to_set

      sites.select do |site|
        site.tags.empty? || site.tags.any? { |tag| partner_tag_ids.include?(tag.id) }
      end
    end
  end
end
