# frozen_string_literal: true

class SitemapsController < ApplicationController
  CACHE_TTL = 1.day
  MAX_URLS_PER_SITEMAP = 50_000
  BASE = 'https://placecal.org'

  skip_before_action :set_supporters
  skip_before_action :set_navigation

  before_action :set_site
  before_action :require_default_site

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

  def require_default_site
    head :not_found unless default_site?
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
    urls = Event.where(dtstart: 3.months.ago..)
                .order(dtstart: :desc)
                .limit(MAX_URLS_PER_SITEMAP)
                .pluck(:id, :updated_at)
                .map { |id, updated_at| url_entry("#{BASE}/events/#{id}", updated_at) }
    wrap_urlset(urls)
  end

  def build_partnerships
    urls = []
    urls << url_entry("#{BASE}/partnerships")

    Site.published.where.not(slug: 'default-site').pluck(:slug, :url, :updated_at).each do |slug, site_url, updated_at|
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
    urls << url_entry("#{BASE}/find-placecal")

    %w[privacy our-story terms-of-use get-in-touch
       community-groups metropolitan-areas vcses
       housing-providers social-prescribers culture-tourism].each do |page|
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
