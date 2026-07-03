# frozen_string_literal: true

module Admin
  class ArticlesController < Admin::ApplicationController
    before_action :set_article, only: %i[edit update destroy]

    def index
      @articles = policy_scope(Article)
      authorize @articles

      respond_to do |format|
        format.html do
          @articles = @articles.order(updated_at: :desc, title: :asc)
          render Views::Admin::Articles::Index.new(articles: @articles)
        end
        format.json do
          render json: ArticleDatatable.new(
            params,
            view_context: view_context,
            articles: @articles
          )
        end
      end
    end

    def new
      @article = params[:article] ? Article.new(permitted_attributes(Article)) : Article.new
      @article.partners = current_user.partners if current_user.partners.one?
      @article.author = current_user unless current_user.root?
      authorize @article
      render Views::Admin::Articles::New.new(article: @article)
    end

    def edit
      authorize @article
      render Views::Admin::Articles::Edit.new(article: @article)
    end

    def create
      attrs = permitted_attributes(Article)
      @article = Article.new(attrs)

      authorize @article

      if save_with_required_partner(attrs)
        flash[:success] = 'Article has been created'
        redirect_to admin_articles_path
      else
        flash.now[:danger] = 'Article has not been created'
        render Views::Admin::Articles::New.new(article: @article), status: :unprocessable_content
      end
    end

    def update
      authorize @article

      if save_with_required_partner(permitted_attributes(@article))
        flash[:success] = 'Article was saved successfully'
        redirect_to edit_admin_article_path(@article)
      else
        flash.now[:danger] = 'Article was not saved'
        render Views::Admin::Articles::Edit.new(article: @article), status: :unprocessable_content
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
      @article = Article.friendly.find(params[:id])
    end

    # Visibility follows the partner (issue #3308): an article with no partners
    # is invisible on every site, so non-staff authors must link at least one.
    # Root and editor may publish partner-less platform posts (consumed via the
    # tag-based API). Checked against the submitted params, before assignment,
    # because assigning partner_ids to a persisted article writes immediately.
    def save_with_required_partner(attrs)
      if missing_required_partner?(attrs)
        @article.errors.add(:base, t('admin.articles.errors.partner_required'))
        false
      else
        @article.update(attrs)
      end
    end

    def missing_required_partner?(attrs)
      return false if current_user.root? || current_user.editor?
      return false unless @article.new_record? || attrs.key?(:partner_ids)

      Array(attrs[:partner_ids]).compact_blank.empty?
    end
  end
end
