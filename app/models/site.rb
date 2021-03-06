# frozen_string_literal: true

class Site < ApplicationRecord
  extend FriendlyId
  extend Enumerize

  friendly_id :name, use: :slugged

  has_one :sites_neighbourhood, dependent: :destroy
  has_one :primary_neighbourhood, -> { where(sites_neighbourhoods: { relation_type: 'Primary' }) }, source: :neighbourhood, through: :sites_neighbourhood

  has_many :sites_neighbourhoods, dependent: :destroy
  has_many :secondary_neighbourhoods, -> { where(sites_neighbourhoods: { relation_type: 'Secondary' }) }, source: :neighbourhood, through: :sites_neighbourhoods

  has_many :neighbourhoods, through: :sites_neighbourhoods

  has_and_belongs_to_many :supporters

  belongs_to :site_admin, class_name: 'User', optional: true

  accepts_nested_attributes_for :sites_neighbourhood
  accepts_nested_attributes_for :sites_neighbourhoods, reject_if: ->(c) { c[:neighbourhood_id].blank? }, allow_destroy: true

  validates :name, :slug, :domain, presence: true
  validates :place_name unless :default_site?

  mount_uploader :logo, SiteLogoUploader
  mount_uploader :footer_logo, SiteLogoUploader
  mount_uploader :hero_image, HeroImageUploader

  # Theme picker
  enumerize :theme,
            in: %i[pink orange green blue custom],
            default: :pink

  def to_s
    "#{id}: #{name}"
  end

  # ASSUMPTION: There is no row in the sites table for the admin site, hence
  # defining the admin subdomain string here.
  ADMIN_SUBDOMAIN = 'admin'

  def default_site?
    slug == 'default-site'
  end

  # ASSUMPTION: All valid sites, other than the default site, are local sites.
  def local_site?
    not default_site?
  end

  # Should we show the neighbourhood lozenge out on this site?
  def show_neighbourhoods?
    neighbourhoods.count > 1
  end

  def join_word
    if neighbourhoods.count > 1
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
    # Parameters:
    #   request must expose these methods; host, subdomain, subdomains
    def find_by_request request

      # First try to find the correct site by the full host name.
      site = Site.find_by( domain: request.host )
      return site if site

      # Is it Marvellous Mossley?
      # TODO: Fix this horrible temporary fix
      return Site.find_by(slug: 'mossley') if request.domain == 'marvellousmossley.org'

      # Fall back to using the subdomain.
      # Typically this will be for non-production sites.
      site_slug =
        if request.subdomain == 'www'
          if request.subdomains.second
            request.subdomains.second
          end
        elsif request.subdomain.present?
          request.subdomain
        end

      # No subdomain? Fall back to the default site.
      site_slug ||= 'default-site'

      Site.find_by(slug: site_slug)
    end
  end
end
