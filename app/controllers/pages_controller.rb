# frozen_string_literal: true

class PagesController < ApplicationController
  # Actions that belong only to the main placecal.org homepage. They must not be
  # reachable on a sub-site subdomain, where they don't belong (see #2463).
  HOMEPAGE_ONLY_ACTIONS = %i[
    find_placecal our_story community_groups metropolitan_areas
    vcses housing_providers social_prescribers culture_tourism
  ].freeze

  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site
  before_action :require_default_site, only: HOMEPAGE_ONLY_ACTIONS

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

  # Homepage-only actions are not valid on sub-sites. When such an action is
  # requested on a real, non-default site, redirect to that site's root rather
  # than letting the page render where it doesn't belong (see #2463).
  # (SitemapsController#require_default_site does the same for its routes but
  # returns 404; here we redirect because these pages have a sub-site equivalent.)
  def require_default_site
    return if current_site.nil? || default_site?

    redirect_to root_path # site root on the current (sub-site) host
  end

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

    @upcoming_events = Rails.cache.fetch('directory/upcoming_events', expires_in: DIRECTORY_CACHE_TTL) do
      EventsQuery.new(site: @site).call(period: 'upcoming')
    end

    @partner_event_counts = Rails.cache.fetch('directory/partner_event_counts', expires_in: DIRECTORY_CACHE_TTL) do
      ids = @recent_partners.map(&:id)
      Event.future(Time.zone.today)
           .where(place_id: ids)
           .or(Event.future(Time.zone.today).where(organiser_id: ids))
           .group(:place_id)
           .count
    end

    render Views::Directory::Home.new(
      partnerships: @partnerships,
      recent_partners: @recent_partners,
      upcoming_events: @upcoming_events,
      partner_event_counts: @partner_event_counts,
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
