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
      render Views::Pages::Home.new(neighbourhoods: @neighbourhoods)
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
    render Views::Pages::TermsOfUse.new
  end

  def privacy
    render Views::Pages::Privacy.new
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

  private

  def render_directory_home
    @partnerships = Site.where(is_published: true)
                        .where.not(slug: 'default-site')
                        .order(partners_count: :desc)
                        .limit(6)
    @recent_partners = Partner.visible.includes(:categories, :address).order(created_at: :desc).limit(5)
    @upcoming_events = EventsQuery.new(site: @site).call(period: 'upcoming')
    @stats = {
      partnerships: Site.where(is_published: true).where.not(slug: 'default-site').count,
      partners: Partner.visible.count,
      events: Event.future(Time.zone.today).count,
      neighbourhoods: Neighbourhood.districts.count
    }

    @partner_locations = build_partner_locations
    @jump_sites = build_jump_sites

    render Views::Pages::DirectoryHome.new(
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
