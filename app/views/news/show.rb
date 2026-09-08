# frozen_string_literal: true

class Views::News::Show < Views::Base
  register_output_helper :article_partner_links
  register_value_helper :article_date

  # The pull quote sits after the third paragraph of the body, or at the end
  # when the body has fewer than three.
  PULL_QUOTE_PARAGRAPH = 3

  prop :article, Article, reader: :private
  prop :site, Site, reader: :private

  def view_template
    content_for(:title) { article.title }

    div(vocab: 'http://schema.org/', typeof: 'Article') do
      Hero(article.title, site.tagline, schema: 'name', section: t('news.show.section'))
      div(class: 'container-public mb-32') do
        Breadcrumb(
          trail: [[t('navigation.site.news'), news_index_path], [article.title, news_path(article)]],
          site_name: site.name
        )
        hr
        render_article_body
      end
    end
  end

  private

  def render_article_body
    div(class: 'g article') do
      div(class: 'gi gi__1-5 article__aside') do
        p(class: 'article__published', title: article.published_at.to_s) do
          plain article_date(article.published_at, t('news.show.date_format'))
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

        render_image

        div(class: 'article__content') { render_body_with_pull_quote }

        div(class: 'article__back') do
          link_to t('news.show.back'), news_index_path
        end
      end
    end
  end

  def render_image
    return if article.article_image.blank?

    div(class: 'article__image') do
      image_tag article.article_image.url, class: 'border'
      p(class: 'article__image-credit') { article.image_credit } if article.image_credit.present?
    end
  end

  # The cached body HTML is a sequence of sanitised <p>...</p> paragraphs
  # (see HtmlRenderCache). Splitting on the closing tag lets us drop the pull
  # quote in after the third paragraph, or at the end if there are fewer.
  #
  # Kramdown separates paragraphs with a blank line, so unless the body ends
  # exactly on a closing tag, the split leaves a trailing whitespace fragment
  # that is not itself a paragraph and must not be treated as one.
  def render_body_with_pull_quote
    html = article.body_html.to_s
    fragments = html.split('</p>')
    trailing = html.end_with?('</p>') ? '' : fragments.pop.to_s

    paragraphs = fragments.map { |paragraph| "#{paragraph}</p>" }
    insert_after = article.pull_quote.present? ? [PULL_QUOTE_PARAGRAPH, paragraphs.length].min - 1 : nil

    if paragraphs.empty?
      render_pull_quote if insert_after
    else
      paragraphs.each_with_index do |paragraph, index|
        raw safe(paragraph)
        render_pull_quote if index == insert_after
      end
    end

    raw safe(trailing) if trailing.present?
  end

  def render_pull_quote
    PullQuote(source: '', quote_context: '', options: {}) { article.pull_quote }
  end
end
