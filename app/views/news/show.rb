# frozen_string_literal: true

class Views::News::Show < Views::Base
  register_output_helper :article_partner_links

  prop :article, Article, reader: :private
  prop :site, Site, reader: :private

  def view_template
    content_for(:title) { article.title }

    div(vocab: 'http://schema.org/', typeof: 'Article') do
      render(Components::Hero.new(article.title, site.tagline, 'name'))
      div(class: 'c c--lg-space-after') do
        render(Components::Breadcrumb.new(
                 trail: [['News', news_index_path], [article.title, news_path(article)]],
                 site_name: site.name
               ))
        hr
        render_article_body
      end
    end
  end

  private

  def render_article_body # rubocop:disable Metrics/AbcSize
    div(class: 'g article') do
      div(class: 'gi gi__1-5 article__aside') do
        p(class: 'article__published', title: article.published_at.to_s) do
          plain article.published_at.strftime('%B %Y')
        end
      end

      div(class: 'gi gi__4-5 article__main') do
        if article.author&.full_name.present?
          h3(class: 'article__author') do
            plain 'By '
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
            p(class: 'article__image-attribute') { 'Image credit and/or title' }
          end
        end

        div(class: 'article__content') do
          raw safe(article.body_html.to_s)
        end

        div(class: 'article__back') do
          link_to 'Back to news', news_path
        end
      end
    end
  end
end
