# frozen_string_literal: true

class Views::News::Index < Views::Base
  register_output_helper :article_partner_links
  register_value_helper :article_summary_text

  prop :articles, ActiveRecord::Relation, reader: :private
  prop :site, Site, reader: :private
  prop :partner, _Nilable(Partner), reader: :private, default: nil
  prop :next_offset, _Nilable(Integer), reader: :private

  def view_template
    content_for(:title) { page_title }
    content_for(:rss_feed) { rss_feed_path }

    Hero(page_title, site.tagline)

    div(class: 'articles') do
      articles.each do |article|
        render_article_card(article)
      end
    end

    p(class: 'articles__pagination') do
      link_to t('news.index.older'), news_index_path(**pagination_params) if articles.count == NewsController::ARTICLES_PER_PAGE
    end

    p(class: 'articles__rss') do
      link_to t('news.index.rss'), rss_feed_path
    end
  end

  private

  def page_title
    if partner
      t('news.index.title_for_partner', partner: partner.name)
    else
      t('news.index.title')
    end
  end

  def pagination_params
    { offset: next_offset, partner: partner&.slug }.compact
  end

  def rss_feed_path
    news_index_path(**{ format: :rss, partner: partner&.slug }.compact)
  end

  def render_article_card(article)
    div(class: 'articles__article-card g') do
      div(class: 'gi gi__1-5 articles__aside') do
        p(class: 'articles__published', title: article.published_at.to_s) do
          plain article.published_at.strftime('%B %Y')
        end
      end

      div(class: 'gi gi__4-5 articles__main') do
        h2(class: 'articles__title') { link_to article.title, news_path(article) }

        if article.partners.present?
          p(class: 'articles__partners') do
            article_partner_links(article)
            plain '.'
          end
        end

        div(class: 'g articles__content') do
          div(class: 'gi articles__body') do
            p { article_summary_text(article) }
          end

          if article.article_image.present?
            div(class: 'gi articles__image') do
              image_tag article.article_image.url, class: 'border'
            end
          end
        end

        p { link_to t('news.index.read_more'), news_path(article), class: 'btn btn--alt btn--mt' }
      end
    end
  end
end
