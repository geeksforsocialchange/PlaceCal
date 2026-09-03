# frozen_string_literal: true

class NewsController < ApplicationController
  ARTICLES_PER_PAGE = 20

  before_action :set_article, only: %i[show]
  before_action :set_site
  before_action :redirect_from_directory

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
    render Views::News::Show.new(article: @article, site: @site)
  end

  private

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
  # publishes, so a 404 never loads every article body (#3368).
  #
  # @return [String, nil] canonical slug of the matching article
  def published_slug_by_title_slug
    wanted = params[:id].to_s
    return nil if wanted.blank?

    scope = current_site ? Article.for_site(current_site) : Article.all
    row = scope.published.pluck(:id, :title, :slug).find do |(_id, title, _slug)|
      title.to_s.parameterize == wanted
    end
    row && (row[2].presence || row[0].to_s)
  end
end
