# frozen_string_literal: true

class Site < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  has_one :sites_neighbourhood, dependent: :destroy
  has_one :primary_neighbourhood, -> { where(sites_neighbourhoods: { relation_type: 'Primary' }) }, source: :neighbourhood, through: :sites_neighbourhood

  has_many :sites_neighbourhoods, dependent: :destroy
  has_many :secondary_neighbourhoods, -> { where(sites_neighbourhoods: { relation_type: 'Secondary' }) }, source: :neighbourhood, through: :sites_neighbourhoods

  has_many :neighbourhoods, through: :sites_neighbourhoods

  has_and_belongs_to_many :supporters

  belongs_to :site_admin, class_name: 'User'

  accepts_nested_attributes_for :sites_neighbourhood
  accepts_nested_attributes_for :sites_neighbourhoods, reject_if: ->(c) { c[:neighbourhood_id].blank? }, allow_destroy: true

  validates :name, :slug, :domain, presence: true

  mount_uploader :logo, SiteLogoUploader
  mount_uploader :footer_logo, SiteLogoUploader
  mount_uploader :hero_image, HeroImageUploader

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

  class << self

    # Find the requested Site from information in the rails request object.
    #
    # Parameters:
    #   request must expose these methods; host, subdomain, subdomains
    def find_by_request request

      # First try to find the correct site by the full host name.
      site = Site.find_by( domain: request.host )
      return site if site

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
