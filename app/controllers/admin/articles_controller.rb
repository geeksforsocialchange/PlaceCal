# frozen_string_literal: true

module Admin
  class ArticlesController < Admin::ApplicationController
    def index
      @articles = policy_scope(Article).order(:title)
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
      @article = Article.new
      authorize @article
    end

    def edit
      authorize @article
    end

    def create
      @article = Article.new
      authorize @article
      respond_to do |format|
        if @article.save
          flash[:success] = 'Article has been created'
          redirect_to admin_articles_path
        else
          flash.now[:danger] = 'Article has not been created'
          render :new
        end
      end
    end

    def update
      authorize @article
      if @article.update(article_params)
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

    def article_params
      params.require(:article).permit(:title, :body, :published_at, :is_draft)
    end
  end
end