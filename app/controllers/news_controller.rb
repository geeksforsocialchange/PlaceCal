# frozen_string_literal: true

class NewsController < ApplicationController
  ARTICLES_PER_PAGE = 20

  before_action :set_article, only: %i[show]
  before_action :set_site

  def index
    @offset = params[:offset].to_i
    @offset = 0 if @offset < 0
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
  end

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_article
    @article = Article.published.find(params[:id])
  end
end
