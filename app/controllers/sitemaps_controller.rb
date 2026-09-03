# frozen_string_literal: true

# Serves sitemaps for the nationwide directory and for each local site.
#
# The directory (no Site row) lists everything: all visible partners, all
# upcoming events, the partnerships index, and the static/news pages.
#
# A local site lists only its own content, with every URL built from the site's
# own base URL (Site#url), so a site's sitemap never points at placecal.org.
# Unpublished sites are still served rather than 404'd, matching robots.txt:
# crawl blocking is SiteRobots' job, and an unlinked sitemap costs nothing.
class SitemapsController < ApplicationController
  CACHE_TTL = 1.day
  MAX_URLS_PER_SITEMAP = 50_000
  BASE = Site::DIRECTORY_URL

  skip_before_action :set_supporters
  skip_before_action :set_navigation

  before_action :set_site

  def index
    render xml: cached_xml('index') { build_index }
  end

  def partners
    render xml: cached_xml('partners') { build_partners }
  end

  def events
    render xml: cached_xml('events') { build_events }
  end

  def partnerships
    render xml: cached_xml('partnerships') { build_partnerships }
  end

  def pages
    render xml: cached_xml('pages') { build_pages }
  end

  private

  # Base URL every entry hangs off: the site's own URL on a site, the
  # directory's otherwise.
  def base_url
    @base_url ||= current_site ? current_site.directory_url.chomp('/') : BASE
  end

  def cached_xml(section, &)
    expires_in CACHE_TTL, public: true
    Rails.cache.fetch("sitemap/#{current_site&.slug || 'directory'}/#{section}", expires_in: CACHE_TTL, &)
  end

  # Partnerships are a directory-only concept (the index of every local site),
  # so a site's sitemap index omits that section.
  def index_sections
    current_site ? %w[partners events pages] : %w[partners events partnerships pages]
  end

  def build_index
    xml = +''
    xml << '<?xml version="1.0" encoding="UTF-8"?>'
    xml << '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    index_sections.each do |section|
      xml << "<sitemap><loc>#{base_url}/sitemap/#{section}.xml</loc></sitemap>"
    end
    xml << '</sitemapindex>'
  end

  def partners_scope
    current_site ? PartnersQuery.new(site: current_site).call.reorder(nil) : Partner.visible
  end

  def build_partners
    urls = partners_scope.pluck(:slug, :updated_at).uniq.map do |slug, updated_at|
      url_entry("#{base_url}/partners/#{slug}", updated_at)
    end
    wrap_urlset(urls)
  end

  def events_scope
    current_site ? EventsQuery.new(site: current_site).scope : Event.all
  end

  def build_events
    # Only events that aren't over (dtend-aware, matching Event#past?) —
    # past event pages are noindexed, and a sitemap listing noindexed URLs
    # draws "submitted URL marked noindex" warnings in Search Console.
    urls = events_scope.where('COALESCE(dtend, dtstart) >= ?', DateTime.current.beginning_of_day)
                       .reorder(dtstart: :desc)
                       .limit(MAX_URLS_PER_SITEMAP)
                       .pluck('events.id', 'events.updated_at')
                       .uniq
                       .map { |id, updated_at| url_entry("#{base_url}/events/#{id}", updated_at) }
    wrap_urlset(urls)
  end

  def build_partnerships
    return wrap_urlset([]) if current_site

    urls = []
    urls << url_entry("#{BASE}/partnerships")

    Site.published.pluck(:slug, :url, :updated_at).each do |slug, site_url, updated_at|
      urls << url_entry("#{BASE}/partnerships/#{slug}", updated_at)
      urls << url_entry(site_url.chomp('/'), updated_at)
    end

    wrap_urlset(urls)
  end

  # terms-of-use is directory-only; privacy and get-in-touch resolve on both.
  # A site that takes no enquiries has no Join link (SiteNavigation#join_navigation),
  # so /get-in-touch should not be advertised for it either. A slug the theme
  # serves as its own page is dropped here and emitted once by #theme_page_entries.
  def static_page_slugs
    slugs = current_site ? %w[privacy get-in-touch] : %w[privacy terms-of-use get-in-touch]
    slugs -= %w[get-in-touch] if current_site && current_site.contact_email.blank?
    slugs - theme_page_slugs
  end

  # @return [Array<String>] slugs of the pages the site's theme serves. The
  #   directory has no site, so it has none.
  def theme_page_slugs
    return [] unless current_site

    @theme_page_slugs ||= Current.theme.pages.keys
  end

  def articles_scope
    current_site ? Article.for_site(current_site).published : Article.published
  end

  def build_pages
    urls = []

    urls << url_entry(base_url)
    urls << url_entry("#{base_url}/partners")
    urls << url_entry("#{base_url}/events")

    static_page_slugs.each do |page|
      urls << url_entry("#{base_url}/#{page}")
    end

    articles_scope.pluck(:slug, :updated_at).uniq.each do |slug, updated_at|
      urls << url_entry("#{base_url}/news/#{slug}", updated_at)
    end

    urls.concat(theme_page_entries)

    wrap_urlset(urls.uniq)
  end

  # Static pages the site's theme serves at /:slug (#3368). The content lives
  # in the theme's views, not in the database, so there is no lastmod.
  def theme_page_entries
    theme_page_slugs.map { |slug| url_entry("#{base_url}/#{slug}") }
  end

  def url_entry(loc, lastmod = nil)
    entry = "<url><loc>#{CGI.escapeHTML(loc)}</loc>"
    entry << "<lastmod>#{lastmod.strftime('%Y-%m-%d')}</lastmod>" if lastmod
    entry << '</url>'
  end

  def wrap_urlset(urls)
    xml = +'<?xml version="1.0" encoding="UTF-8"?>'
    xml << '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    urls.each { |u| xml << u }
    xml << '</urlset>'
  end
end
