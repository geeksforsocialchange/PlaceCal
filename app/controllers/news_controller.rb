# frozen_string_literal: true

class NewsController < ApplicationController
  # Caps the title-slug candidates one 404 reads: titles with little ASCII in them match most slugs.
  FALLBACK_SCAN_LIMIT = 2_000

  ARTICLES_PER_PAGE = 20

  before_action :set_site
  before_action :redirect_from_directory
  # After the directory redirect: a bogus slug on the nationwide directory must
  # never reach the articles table (#3368).
  before_action :set_article, only: %i[show]

  def index
    @offset = params[:offset].to_i
    @offset = 0 if @offset.negative?

    # Fetch one extra record beyond the page size so we know whether an
    # older page exists, without a separate COUNT query.
    fetched = Article
              .for_site(@site)
              .published
              .by_publish_date
              .offset(@offset)
              .limit(ARTICLES_PER_PAGE + 1)
              .to_a

    @has_more = fetched.size > ARTICLES_PER_PAGE
    @articles = fetched.first(ARTICLES_PER_PAGE)

    render Views::Sites::News::Index.new(articles: @articles, site: @site, offset: @offset, has_more: @has_more)
  end

  def show
    previous_article, next_article = adjacent_articles
    render Views::Sites::News::Show.new(article: @article, site: @site,
                                        previous_article: previous_article, next_article: next_article)
  end

  private

  # Neighbours in the index's order, among this site's published articles.
  #
  # @return [Array(Article, nil), Array(nil, Article), Array(nil, nil)]
  def adjacent_articles
    return [nil, nil] if current_site.nil?

    site_articles = Article.for_site(current_site).published
    return [nil, nil] unless site_articles.exists?(@article.id)

    [site_articles.listed_before(@article).first, site_articles.listed_after(@article).first]
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_article
    @article = Article.published.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    slug = published_slug_by_title_slug or raise
    redirect_to news_path(slug), status: :moved_permanently
  end

  # API consumers built article URLs from the title (#3368), which can differ
  # from the stored slug. SQL narrows the candidates; parameterize decides.
  #
  # @return [String, nil] canonical slug of the matching article
  def published_slug_by_title_slug
    return nil if current_site.nil?

    wanted = params[:id].to_s
    return nil if wanted.blank?

    rows = Article.for_site(current_site).published.title_slug_candidates(wanted).by_publish_date
                  .limit(FALLBACK_SCAN_LIMIT).pluck(:id, :title, :slug, :published_at)
    row = rows.find { |(_id, title, _slug, _published_at)| title.to_s.parameterize == wanted }
    row && (row[2].presence || row[0].to_s)
  end
end
