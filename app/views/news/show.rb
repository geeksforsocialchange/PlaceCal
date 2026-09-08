# frozen_string_literal: true

class Views::News::Show < Views::Base
  register_output_helper :article_partner_links

  prop :article, Article, reader: :private
  prop :site, Site, reader: :private
  # Computed in NewsController#show, by publish date within this site's own
  # articles. Either may be nil at either end of the list.
  prop :previous_article, _Nilable(::Article), reader: :private, default: nil
  prop :next_article, _Nilable(::Article), reader: :private, default: nil

  def view_template
    content_for(:title) { article.title }

    div(vocab: 'http://schema.org/', typeof: 'Article') do
      Hero(article.title, site.tagline, schema: 'name', section: t('news.show.section'),
                                        back: [t('news.show.back_to_index'), news_index_path])
      div(class: 'container-public mb-32') do
        Breadcrumb(
          trail: [[t('navigation.site.news'), news_index_path], [article.title, news_path(article)]],
          site_name: site.name
        )
        hr
        render_article_body
        render_page_actions
      end
    end
  end

  private

  def render_article_body
    div(class: 'g article') do
      div(class: 'gi gi__1-5 article__aside') do
        p(class: 'article__published', title: article.published_at.to_s) do
          plain article.published_at.strftime(t('news.show.date_format'))
        end
      end

      div(class: 'gi gi__4-5 article__main') do
        if article.author&.full_name.present?
          # A byline, not a section heading: as an h3 straight after the
          # hero h1 it failed axe's heading-order rule on every article.
          p(class: 'article__author') do
            plain t('news.show.by')
            em { article.author.full_name }
          end
        end

        if article.partners.present?
          p(class: 'article__partners') do
            article_partner_links(article)
            plain '.'
          end
        end

        if article.article_image.present?
          div(class: 'article__image') do
            image_tag article.article_image.url, class: 'border'
          end
        end

        div(class: 'article__content') do
          raw safe(article.body_html.to_s)
        end

        div(class: 'article__back') do
          link_to t('news.show.back'), news_index_path
        end
      end
    end
  end

  # Page actions row (Components::PageActions, #3368): previous/next article
  # by publish date within this site, either of which may not exist at the
  # ends of the list, then back to the index.
  def render_page_actions
    links = []
    links << [t('news.show.previous'), news_path(previous_article)] if previous_article
    links << [t('news.show.next'), news_path(next_article)] if next_article
    links << [t('news.show.go_back'), news_index_path]
    PageActions(links: links)
  end
end
