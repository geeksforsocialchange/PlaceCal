# frozen_string_literal: true

class Views::News::Show < Views::Base
  register_output_helper :article_partner_links
  register_value_helper :article_summary_text

  prop :article, Article, reader: :private
  prop :site, Site, reader: :private

  def view_template
    set_content_for_tags

    div(vocab: 'http://schema.org/', typeof: 'Article') do
      Hero(article.title, site.tagline, 'name')
      div(class: 'container-public mb-32') do
        Breadcrumb(
          trail: [[t('navigation.news'), news_index_path], [article.title, news_path(article)]],
          site_name: site.name
        )
        hr
        render_article_body
      end
    end
  end

  private

  def set_content_for_tags
    content_for(:title) { article.title }
    content_for(:description) { article_summary_text(article) }

    og_image = article.og_image_path
    return if og_image.blank?

    content_for(:image) { og_image }
    content_for(:image_alt) { article.title }
  end

  def render_article_body
    div(class: 'g article') do
      div(class: 'gi gi__1-5 article__aside') do
        p(class: 'article__published', title: article.published_at.to_s) do
          plain article.published_at.strftime('%B %Y')
        end
      end

      div(class: 'gi gi__4-5 article__main') do
        if article.author&.full_name.present?
          h3(class: 'article__author') do
            plain t('news.show.by')
            plain ' '
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
end
