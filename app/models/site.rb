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

  has_and_belongs_to_many :supporters

  belongs_to :site_admin, class_name: 'User', optional: true

  accepts_nested_attributes_for :sites_neighbourhood
  accepts_nested_attributes_for :sites_neighbourhoods, reject_if: lambda { |c|
                                                                    c[:neighbourhood_id].blank?
                                                                  }, allow_destroy: true

  validates :name, :slug, :url, presence: true
  validates :place_name unless :default_site?
  validates :hero_text, length: { maximum: 120 }
  validates :url, format: { with: %r{\Ahttps://[^\s,]+\z}, message: 'A url must start with "https://"' }

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
    owned_neighbourhood_ids.count > 1
  end

  def self.badge_zoom_level_label(value)
    value.second.to_s.titleize
  end

  def join_word
    if owned_neighbourhoods.count > 1
      'near'
    else
      'in'
    end
  end

  # Get a count of all the events this week
  def events_this_week
    Event.for_site(self).find_by_week(Time.now).count
  end

  # Get a count of all the events last week
  def events_last_week
    Event.for_site(self).find_by_week(Time.now - 1.week).count
  end

  def stylesheet_link
    return 'home' if default_site?

    if theme == :custom
      "themes/custom/#{slug}"
    else
      "themes/#{theme}"
    end
  end

  class << self
    # Find the requested Site from information in the rails request object.
    #
    # @param request The request must expose the methods: host, subdomain, subdomains
    # @return [Site]
    def find_by_request(request)
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

    # Get a list of Sites that are either share neighbourhoods
    # with the Site, or share Tags with the Site
    #
    # @param [Partner]
    # @return [ActiveRecord::Relation<Site>]
    def sites_that_contain_partner(partner)
      sites = Site.all.order(:name)
      site_partners = []
      sites.each do |site|
        partner_ids = Partner.for_site(site).pluck(:id)
        site_partners.push({ site: site, partner_ids: partner_ids })
      end
      site_partners.select { |sp| sp[:partner_ids].include? partner.id }
                   .map { |sp| sp[:site] }
    end
  end
end
