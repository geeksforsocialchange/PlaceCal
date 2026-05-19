# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site

  def home
    if default_site?
      render_directory_home
    else
      @neighbourhoods = Site.published.select do |site|
        site.tags.none? { |tag| tag.type == 'Partnership' }
      end
      render Views::Homepage::Home.new(neighbourhoods: @neighbourhoods)
    end
  end

  def find_placecal
    @neighbourhoods = Site.published.select do |site|
      site.tags.none? { |tag| tag.type == 'Partnership' }
    end
    @partnerships = Site.published.select do |site|
      site.tags.any? { |tag| tag.type == 'Partnership' }
    end
    render Views::Homepage::FindPlacecal.new(neighbourhoods: @neighbourhoods, partnerships: @partnerships)
  end

  def terms_of_use
    render Views::Directory::TermsOfUse.new
  end

  def privacy
    render Views::Directory::Privacy.new
  end

  def our_story
    render Views::Homepage::OurStory.new
  end

  def community_groups
    render Views::Homepage::CommunityGroups.new
  end

  def vcses
    render Views::Homepage::Vcses.new
  end

  def housing_providers
    render Views::Homepage::HousingProviders.new
  end

  def metropolitan_areas
    render Views::Homepage::MetropolitanAreas.new
  end

  def social_prescribers
    render Views::Homepage::SocialPrescribers.new
  end

  def culture_tourism
    render Views::Homepage::CultureTourism.new
  end

  def robots
    if current_site
      render plain: current_site.robots
    else
      # Admin subdomain or no site found - disallow all indexing
      render plain: "User-agent: *\nDisallow: /"
    end
  end

  NEIGHBOURHOOD_UNIT_RANK = %w[ward district county region].freeze
  DIRECTORY_CACHE_TTL = 1.day

  private

  def render_directory_home
    @stats = Rails.cache.fetch('directory/stats', expires_in: DIRECTORY_CACHE_TTL) do
      {
        partnerships: Site.where(is_published: true).where.not(slug: 'default-site').count,
        partners: Partner.visible.count,
        events: Event.where(dtstart: Time.zone.today..30.days.from_now).count,
        neighbourhoods: Neighbourhood.districts.count
      }
    end

    @partner_locations = Rails.cache.fetch('directory/partner_locations', expires_in: DIRECTORY_CACHE_TTL) do
      build_partner_locations
    end

    @jump_sites = Rails.cache.fetch('directory/jump_sites', expires_in: DIRECTORY_CACHE_TTL) do
      build_jump_sites.to_a
    end

    @partnerships = Rails.cache.fetch('directory/partnerships', expires_in: DIRECTORY_CACHE_TTL) do
      Site.where(is_published: true)
          .where.not(slug: 'default-site')
          .order(partners_count: :desc)
          .limit(6)
          .to_a
    end

    @recent_partners = Rails.cache.fetch('directory/recent_partners', expires_in: DIRECTORY_CACHE_TTL) do
      Partner.visible.includes(:categories, :address).order(created_at: :desc).limit(5).to_a
    end

    @upcoming_events = EventsQuery.new(site: @site).call(period: 'upcoming')

    render Views::Directory::Home.new(
      partnerships: @partnerships,
      recent_partners: @recent_partners,
      upcoming_events: @upcoming_events,
      stats: @stats,
      partner_locations: @partner_locations,
      jump_sites: @jump_sites
    )
  end

  def build_jump_sites
    partnership_ids = Tag.where(type: 'Partnership').joins(:sites).select('sites.id')
    sites = Site.where(is_published: true)
                .where.not(slug: 'default-site')
                .where.not(id: partnership_ids)
                .order(partners_count: :desc)
                .limit(3)
    return sites if sites.any?

    Site.where(slug: %w[manchester london norwich], is_published: true)
  end

  def build_partner_locations
    locations = Partner.visible.joins(:address)
                       .where.not(addresses: { latitude: nil })
                       .pluck(:name, :slug, 'addresses.latitude', 'addresses.longitude')
                       .map { |name, slug, lat, lon| { lat: lat, lon: lon, name: name, url: partner_path(slug) } }

    addressless = Partner.visible.where(address_id: nil).includes(service_areas: :neighbourhood)
    return locations if addressless.none?

    sa_nhood_ids = addressless.flat_map { |p| p.service_areas.map(&:neighbourhood_id) }.compact.uniq
    centroid_cache = neighbourhood_centroids(sa_nhood_ids)

    addressless.find_each do |p|
      best = p.service_areas.filter_map(&:neighbourhood)
              .select { |n| NEIGHBOURHOOD_UNIT_RANK.include?(n.unit) }
              .min_by { |n| NEIGHBOURHOOD_UNIT_RANK.index(n.unit) }
      next unless best

      coords = centroid_cache[best.id]
      next unless coords

      locations << { lat: coords[0], lon: coords[1], name: p.name, url: partner_path(p.slug) }
    end

    locations
  end

  def neighbourhood_centroids(neighbourhood_ids)
    cache = {}
    Neighbourhood.where(id: neighbourhood_ids).find_each do |n|
      addrs = Address.where(neighbourhood_id: n.id).where.not(latitude: nil)
      unless addrs.exists?
        desc_ids = n.descendant_ids
        addrs = Address.where(neighbourhood_id: desc_ids).where.not(latitude: nil) if desc_ids.any?
      end
      next unless addrs.exists?

      cache[n.id] = [addrs.average(:latitude).to_f, addrs.average(:longitude).to_f]
    end
    cache
  end
end
