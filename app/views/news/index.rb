# frozen_string_literal: true

class Views::News::Index < Views::Base
  register_output_helper :article_partner_links
  register_value_helper :article_summary_text
  register_value_helper :article_date

  prop :articles, _Array(Article), reader: :private
  prop :site, Site, reader: :private
  prop :offset, Integer, reader: :private
  prop :has_more, _Boolean, reader: :private

  def view_template
    content_for(:title) { t('news.index.page_title') }

    Hero(t('news.index.title'), site.tagline, standfirst: t('news.index.standfirst'))

    div(class: 'articles') do
      articles.each do |article|
        render_article_card(article)
      end
    end

    render_pagination
  end

  private

  def render_article_card(article)
    div(class: 'articles__article-card g') do
      div(class: 'gi gi__1-5 articles__aside') do
        p(class: 'articles__published', title: article.published_at.to_s) do
          plain article_date(article.published_at, t('news.index.date_format'))
        end
      end

      div(class: 'gi gi__4-5 articles__main') do
        h2(class: 'articles__title') { link_to article.title, news_path(article) }

        p(class: 'articles__partners') { article_partner_links(article) } if article.partners.present?

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

  # Both links are optional: "Recent news" only appears once you have paged
  # past the first page, "Older" only while a next page actually exists (the
  # controller knows this from fetching one extra record).
  def render_pagination
    return unless offset.positive? || has_more

    nav(class: 'articles__pagination') do
      render_newer_link
      render_older_link
    end
  end

  def render_newer_link
    return unless offset.positive?

    newer_offset = [offset - NewsController::ARTICLES_PER_PAGE, 0].max
    href = newer_offset.zero? ? news_index_path : "#{news_index_path}?offset=#{newer_offset}"
    link_to t('news.index.newer'), href, class: 'articles__pagination-newer'
  end

  def render_older_link
    return unless has_more

    older_offset = offset + NewsController::ARTICLES_PER_PAGE
    link_to t('news.index.older'), "#{news_index_path}?offset=#{older_offset}", class: 'articles__pagination-older'
  end
end
