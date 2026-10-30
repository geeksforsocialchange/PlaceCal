# frozen_string_literal: true

class Views::Sites::News::Index < Views::Base
  register_output_helper :article_partner_links
  register_value_helper :article_summary_text
  register_value_helper :article_date

  prop :articles, _Array(Article), reader: :private
  prop :site, Site, reader: :private
  prop :offset, Integer, reader: :private
  prop :has_more, _Boolean, reader: :private

  def view_template
    content_for(:title) { t('news.index.page_title') }

    Shared::Hero(t('news.index.title'), site.tagline, standfirst: t('news.index.standfirst'))

    div(class: 'articles w-9/10 mx-auto my-8') do
      articles.each do |article|
        render_article_card(article)
      end
    end

    render_pagination
  end

  private

  def render_article_card(article)
    div(class: 'articles__article-card grid gap-x-4.5 lg:grid-cols-aside-main my-4 border-b-2 border-tertiary-light') do
      div(class: 'articles__aside') do
        p(class: 'articles__published m-0 font-bold text-right max-md:text-left max-md:pb-4', title: article.published_at.to_s) do
          plain article_date(article.published_at, t('news.index.date_format'))
        end
      end

      div(class: 'articles__main') do
        h2(class: 'articles__title mt-0 leading-none') { link_to article.title, news_path(article), class: 'text-foreground no-underline' }

        p(class: 'articles__partners text-sm') { article_partner_links(article) } if article.partners.present?

        div(class: 'articles__content flex gap-x-4.5') do
          div(class: 'articles__body grow-5 max-md:order-2') do
            p { article_summary_text(article) }
          end

          if article.article_image.present?
            div(class: 'articles__image grow-5 max-md:order-1') do
              image_tag article.article_image.url, class: 'border max-w-full rounded-card overflow-hidden'
            end
          end
        end

        p { UI::Button(variant: :outline, href: news_path(article), class: 'btn btn--alt mt-4') { t('news.index.read_more') } }
      end
    end
  end

  # Both links are optional: "Recent news" only appears once you have paged
  # past the first page, "Older" only while a next page actually exists (the
  # controller knows this from fetching one extra record).
  def render_pagination
    return unless offset.positive? || has_more

    nav(class: 'articles__pagination p-8') do
      render_newer_link
      render_older_link
    end
  end

  def render_newer_link
    return unless offset.positive?

    newer_offset = [offset - NewsController::ARTICLES_PER_PAGE, 0].max
    href = newer_offset.zero? ? news_index_path : "#{news_index_path}?offset=#{newer_offset}"
    link_to t('news.index.newer'), href
  end

  def render_older_link
    return unless has_more

    older_offset = offset + NewsController::ARTICLES_PER_PAGE
    link_to t('news.index.older'), "#{news_index_path}?offset=#{older_offset}"
  end
end
