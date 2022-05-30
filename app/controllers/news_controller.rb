# frozen_string_literal: true

class NewsController < ApplicationController
  before_action :set_article, only: %i[show]
  before_action :set_site

  def index
    @articles = Article
      .for_site(@site)
      .published
      .order(:published_at)
      .all
  end

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_article
    @article = Article.published.find(params[:id])
  end
end
