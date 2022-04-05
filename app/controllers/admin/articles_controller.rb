# frozen_string_literal: true

module Admin
  class ArticlesController < Admin::ApplicationController
    before_action :set_article, only: %i[edit update destroy]

    def index
      @articles = policy_scope(Article).order({ updated_at: :desc }, :title)
      authorize @articles

      respond_to do |format|
        format.html
        format.json {
          render json: ArticleDatatable.new(
            params,
            view_context: view_context,
            articles: @articles
          )
        }
      end
    end

    def new
      @article = Article.new(permitted_attributes(Article))
      @article.partners = current_user.partners if current_user.partners.count == 1
      @article.author = current_user unless current_user.root?
      authorize @article
    end

    def edit
      authorize @article
    end

    def create
      @article = Article.new(permitted_attributes(Article))

      authorize @article

      if @article.save
        flash[:success] = 'Article has been created'
        redirect_to admin_articles_path
      else
        flash.now[:danger] = 'Article has not been created'
        render :new
      end
    end

    def update
      authorize @article

      if @article.update(permitted_attributes(@article))
        flash[:success] = 'Article was saved successfully'
        redirect_to admin_articles_path
      else
        flash.now[:danger] = 'Article was not saved'
        render :edit
      end
    end

    def destroy
      authorize @article
      @article.destroy
      flash[:success] = 'Article was deleted'
      redirect_to admin_articles_url
    end

    private

    def set_article
      @article = Article.find(params[:id])
    end
  end
end
