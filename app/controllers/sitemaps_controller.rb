# frozen_string_literal: true

class SitemapsController < ApplicationController
  CACHE_TTL = 1.day
  MAX_URLS_PER_SITEMAP = 50_000
  BASE = Site::DIRECTORY_URL

  skip_before_action :set_supporters
  skip_before_action :set_navigation

  before_action :set_site
  before_action :require_directory

  def index
    render xml: cached_xml('sitemap/index') { build_index }
  end

  def partners
    render xml: cached_xml('sitemap/partners') { build_partners }
  end

  def events
    render xml: cached_xml('sitemap/events') { build_events }
  end

  def partnerships
    render xml: cached_xml('sitemap/partnerships') { build_partnerships }
  end

  def pages
    render xml: cached_xml('sitemap/pages') { build_pages }
  end

  private

  def require_directory
    head :not_found unless directory_request?
  end

  def cached_xml(key, &)
    expires_in CACHE_TTL, public: true
    Rails.cache.fetch(key, expires_in: CACHE_TTL, &)
  end

  def build_index
    xml = +''
    xml << '<?xml version="1.0" encoding="UTF-8"?>'
    xml << '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    %w[partners events partnerships pages].each do |section|
      xml << "<sitemap><loc>#{BASE}/sitemap/#{section}.xml</loc></sitemap>"
    end
    xml << '</sitemapindex>'
  end

  def build_partners
    urls = Partner.visible.pluck(:slug, :updated_at).map do |slug, updated_at|
      url_entry("#{BASE}/partners/#{slug}", updated_at)
    end
    wrap_urlset(urls)
  end

  def build_events
    # Only events that aren't over (dtend-aware, matching Event#past?) —
    # past event pages are noindexed, and a sitemap listing noindexed URLs
    # draws "submitted URL marked noindex" warnings in Search Console.
    urls = Event.where('COALESCE(dtend, dtstart) >= ?', DateTime.current.beginning_of_day)
                .order(dtstart: :desc)
                .limit(MAX_URLS_PER_SITEMAP)
                .pluck(:id, :updated_at)
                .map { |id, updated_at| url_entry("#{BASE}/events/#{id}", updated_at) }
    wrap_urlset(urls)
  end

  def build_partnerships
    urls = []
    urls << url_entry("#{BASE}/partnerships")

    Site.published.pluck(:slug, :url, :updated_at).each do |slug, site_url, updated_at|
      urls << url_entry("#{BASE}/partnerships/#{slug}", updated_at)
      urls << url_entry(site_url.chomp('/'), updated_at)
    end

    wrap_urlset(urls)
  end

  def build_pages
    urls = []

    urls << url_entry(BASE)
    urls << url_entry("#{BASE}/partners")
    urls << url_entry("#{BASE}/events")

    %w[privacy terms-of-use get-in-touch].each do |page|
      urls << url_entry("#{BASE}/#{page}")
    end

    Article.published.pluck(:slug, :updated_at).each do |slug, updated_at|
      urls << url_entry("#{BASE}/news/#{slug}", updated_at)
    end

    wrap_urlset(urls)
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
