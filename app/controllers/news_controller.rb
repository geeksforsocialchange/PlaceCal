# frozen_string_literal: true

class NewsController < ApplicationController
  # Bounds what a scanner walking /news/<anything> can make one 404 cost.
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
    @next_offset = @offset + ARTICLES_PER_PAGE

    @article_count = Article
                     .for_site(@site)
                     .published
                     .count

    @articles = Article
                .for_site(@site)
                .published
                .by_publish_date
                .offset(@offset)
                .limit(ARTICLES_PER_PAGE)

    render Views::News::Index.new(articles: @articles, site: @site, next_offset: @next_offset)
  end

  def show
    previous_article, next_article = adjacent_articles
    render Views::News::Show.new(article: @article, site: @site,
                                 previous_article: previous_article, next_article: next_article)
  end

  private

  # The article immediately newer ("previous") and immediately older ("next")
  # than @article, within this site's own published articles, ordered the
  # same way the index page lists them (by_publish_date: newest first).
  #
  # Article.for_site builds its own joins and calls `.distinct` (see the
  # model), so a plain `pluck(:id)` here would ask Postgres to ORDER BY
  # published_at while only selecting id - "for SELECT DISTINCT, ORDER BY
  # expressions must appear in select list". Plucking published_at alongside
  # id keeps the order column in the select list and sidesteps that
  # altogether, without loading full records just to find two neighbours.
  #
  # @return [Array(Article, nil), Array(nil, Article), Array(nil, nil)]
  def adjacent_articles
    return [nil, nil] if current_site.nil?

    ids = Article.for_site(current_site).published.by_publish_date.pluck(:id, :published_at).map(&:first)
    index = ids.index(@article.id)
    return [nil, nil] if index.nil?

    previous_article = index.positive? ? Article.find(ids[index - 1]) : nil
    next_article = index < ids.size - 1 ? Article.find(ids[index + 1]) : nil
    [previous_article, next_article]
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_article
    @article = Article.published.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    slug = published_slug_by_title_slug or raise
    redirect_to news_path(slug), status: :moved_permanently
  end

  # Sites that consumed PlaceCal news through the API built their own URLs
  # from the article title (#3368), which does not always match the
  # slug stored here. When the requested slug matches a published article's
  # title-derived slug, send the visitor to the canonical URL instead of a
  # 404. Generic: keyed on nothing site-specific.
  #
  # Only slugs and titles are read, and only from the articles this site
  # publishes, so a 404 never loads every article body (#3368). Without a site
  # there is nothing site-specific to rescue, so the directory does no work at
  # all rather than scanning every published article platform-wide.
  #
  # The match is String#parameterize, which has no SQL equivalent worth
  # writing, so it happens in Ruby. Article.for_site joins through partner tags
  # with no DISTINCT, so the row count is articles times tag matches rather
  # than articles: distinct collapses that, and the limit bounds what a scanner
  # walking /news/wp-admin, /news/backup and the rest can make one 404 cost. A
  # site with more published articles than the limit loses the rescue on the
  # oldest of them, which is the right thing to lose.
  #
  # @return [String, nil] canonical slug of the matching article
  def published_slug_by_title_slug
    return nil if current_site.nil?

    wanted = params[:id].to_s
    return nil if wanted.blank?

    rows = Article.for_site(current_site).published.distinct.limit(FALLBACK_SCAN_LIMIT).pluck(:id, :title, :slug)
    row = rows.find { |(_id, title, _slug)| title.to_s.parameterize == wanted }
    row && (row[2].presence || row[0].to_s)
  end
end
