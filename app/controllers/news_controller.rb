# frozen_string_literal: true

class NewsController < ApplicationController
  include Pagy::Offset::Method

  ARTICLES_PER_PAGE = 20

  before_action :set_article, only: %i[show]
  before_action :set_site
  before_action :set_partner_filter, only: %i[index]

  def index
    respond_to do |format|
      format.html do
        if directory_request?
          render_directory_index
        else
          render_site_index
        end
      end
      format.rss { render_feed }
    end
  end

  def show
    if directory_request?
      render Views::Directory::News::Show.new(article: @article)
    else
      render Views::News::Show.new(article: @article, site: @site)
    end
  end

  private

  def set_article
    @article = Article.published.friendly.find(params[:id])
  end

  def set_partner_filter
    @partner = Partner.friendly.find(params[:partner]) if params[:partner].present?
  end

  # Published articles for this host (site-scoped or platform-wide on the
  # directory), optionally narrowed to one partner, newest first
  def base_articles
    articles = directory_request? ? Article.published : Article.for_site(@site)
    articles = articles.for_partner(@partner) if @partner
    articles.by_publish_date
  end

  def render_site_index
    @offset = params[:offset].to_i
    @offset = 0 if @offset.negative?
    @next_offset = @offset + ARTICLES_PER_PAGE

    articles = base_articles
    @article_count = articles.count
    @articles = articles.offset(@offset).limit(ARTICLES_PER_PAGE)

    render Views::News::Index.new(
      articles: @articles, site: @site, partner: @partner, next_offset: @next_offset
    )
  end

  # RSS 2.0 (issue #3308 Phase 3): same scoping as the HTML index — per site,
  # per partner via ?partner=, or platform-wide on the directory
  def render_feed
    @articles = base_articles.includes(:partners).limit(ARTICLES_PER_PAGE)
    @feed_title = feed_title
    @feed_description = @site&.tagline.presence || t('news.feed.description')

    render :index, layout: false
  end

  def feed_title
    name = @site&.name || 'PlaceCal'
    if @partner
      t('news.feed.title_for_partner', name: name, partner: @partner.name)
    else
      t('news.feed.title', name: name)
    end
  end

  def render_directory_index
    articles = base_articles.includes(partners: [{ address: :neighbourhood }, { service_areas: :neighbourhood }])
    @pagy, @articles = pagy(articles, limit: ARTICLES_PER_PAGE)
    @area_labels = PartnersQuery.area_labels(@articles.flat_map(&:partners).uniq)

    render Views::Directory::News::Index.new(
      articles: @articles, pagy: @pagy, partner: @partner, area_labels: @area_labels
    )
  end
end
