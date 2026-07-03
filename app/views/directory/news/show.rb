# frozen_string_literal: true

class Views::Directory::News::Show < Views::Base
  register_output_helper :article_partner_links
  register_value_helper :article_summary_text

  prop :article, Article, reader: :private

  def view_template
    set_content_for_tags

    div(vocab: 'http://schema.org/', typeof: 'Article') do
      Directory::PageHero(
        title: article.title,
        kicker: kicker,
        breadcrumb_label: t('navigation.news'),
        breadcrumb_path: news_index_path
      )

      div(class: 'container-public py-8') do
        div(class: 'max-w-(--width-prose-lg)') do
          render_byline

          img(src: article.article_image.url, alt: '', class: 'rounded-lg mb-6 max-w-full') if article.article_image.present?

          div(class: 'markdown-content text-base leading-relaxed', property: 'articleBody') do
            raw safe(article.body_html.to_s)
          end

          div(class: 'mt-8') do
            link_to t('directory.news.show.back'), news_index_path,
                    class: 'with-no-sass text-foreground underline decoration-primary decoration-2 underline-offset-2 hover:text-foreground/80'
          end
        end
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

  def kicker
    date = article.published_at.strftime('%-d %B %Y')
    author = article.author_name
    author.present? ? "#{date} · #{t('directory.news.show.by')} #{author}" : date
  end

  def render_byline
    return if article.partners.blank?

    p(class: 'text-sm text-tertiary mb-6', property: 'publisher') do
      article_partner_links(article)
      plain '.'
    end
  end
end
