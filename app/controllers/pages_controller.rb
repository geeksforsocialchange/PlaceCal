# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :set_primary_neighbourhood, only: [:site]
  before_action :set_site

  # Only ever reached as the nationwide directory: hosts with a Site route to
  # sites#index (Sites::Local), the admin subdomain has its own root, and the
  # join subdomain has its own routes/catch-all. The legacy pre-directory
  # homepage (Views::Homepage::Home) was unreachable and has been deleted.
  def home
    render_directory_home
  end

  def terms_of_use
    render Views::Directory::MarkdownPage.new(
      slug: 'terms_of_use',
      title: t('directory.pages.terms_of_use.title'),
      breadcrumb_label: t('directory.pages.terms_of_use.breadcrumb'),
      document_title: t('directory.pages.terms_of_use.document_title')
    )
  end

  def privacy
    # A theme may serve its own privacy copy at the conventional URL (#3368,
    # D14). Core routes /privacy, so the theme's `privacy` page is never
    # reached by the /:slug catch-all; this action looks it up itself.
    theme_page = theme_page_view('privacy')
    return render_theme_page(theme_page) if theme_page

    render Views::Directory::MarkdownPage.new(
      slug: 'privacy',
      title: t('directory.pages.privacy.title'),
      breadcrumb_label: t('directory.pages.privacy.breadcrumb'),
      document_title: t('directory.pages.privacy.document_title')
    )
  end

  # Static content page served by the site's theme at /:slug (#3368). The
  # catch-all route is matched last, so anything core routes never reaches
  # here. Core holds no page content: the theme's view supplies all of it.
  def show
    theme_page = theme_page_view(params[:slug])
    raise ActiveRecord::RecordNotFound unless theme_page

    render_theme_page(theme_page)
  end

  def our_story
    render Views::Directory::OurStory.new
  end

  def robots
    # One path, a different body per host, the same as the sitemap and the
    # manifest: a shared cache keying on the path alone would hand one site's
    # robots.txt to another.
    response.headers['Vary'] = 'Host'
    if current_site
      render plain: current_site.robots
    elsif directory_request? || join_site_request?
      # The apex serves the nationwide directory and join.placecal.org is the
      # public marketing site: both always crawlable
      render plain: Site.directory_robots
    else
      # Admin subdomain - disallow all indexing
      render plain: "User-agent: *\nDisallow: /"
    end
  end

  DIRECTORY_CACHE_TTL = 1.day

  # ONS GSS codes for the places featured as homepage "jump" links, in display
  # order. Pinned by code (stable across environments) rather than by id.
  JUMP_NEIGHBOURHOOD_CODES = %w[
    E08000003
    E12000007
    E07000148
    E08000035
    E08000021
  ].freeze

  private

  # @return [Class, nil] the theme view for this slug. The nationwide directory
  #   has no Site and so no theme pages; an unregistered slug, or a view class
  #   that no longer resolves, both give nil.
  def theme_page_view(slug)
    return nil if current_site.nil?

    Current.theme.page_view_class(slug)
  end

  def render_theme_page(view_class)
    render view_class.new(site: current_site)
  end

  def render_directory_home
    @stats = DirectoryStatsQuery.fetch_cached

    @partner_locations = Rails.cache.fetch('directory/partner_locations', expires_in: DIRECTORY_CACHE_TTL) do
      PartnerLocationsQuery.new.call.map do |location|
        { lat: location[:lat], lon: location[:lon], name: location[:name], url: partner_path(location[:slug]) }
      end
    end

    @jump_neighbourhoods = Rails.cache.fetch('directory/jump_neighbourhoods', expires_in: DIRECTORY_CACHE_TTL) do
      build_jump_neighbourhoods.to_a
    end

    @partnerships = Rails.cache.fetch('directory/partnerships', expires_in: DIRECTORY_CACHE_TTL) do
      Site.where(is_published: true)
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
      EventsQuery.upcoming_counts_by_partner(@recent_partners.map(&:id))
    end

    render Views::Directory::Home.new(
      partnerships: @partnerships,
      recent_partners: @recent_partners,
      upcoming_events: @upcoming_events,
      partner_event_counts: @partner_event_counts,
      stats: @stats,
      partner_locations: @partner_locations,
      jump_neighbourhoods: @jump_neighbourhoods
    )
  end

  def build_jump_neighbourhoods
    found = Neighbourhood.latest_release
                         .where(unit_code_value: JUMP_NEIGHBOURHOOD_CODES)
                         .index_by(&:unit_code_value)
    JUMP_NEIGHBOURHOOD_CODES.filter_map { |code| found[code] }
  end
end
