# frozen_string_literal: true

class Views::Sites::News::Index < Views::Base
  theme_scope :news_index,
              parts: {
                root: 'The list of article cards.',
                card: 'One article.',
                aside: 'The card\'s date column.',
                published: 'The publication date.',
                main: 'The card\'s main column: title, partners, then the summary and image.',
                title: 'The card\'s h2, holding the link to the article.',
                partners: 'The partners the article is about, linked. Only when it names some.',
                content: 'The row holding the summary and the image.',
                body: 'The summary and the read-more button.',
                image: 'The article\'s image. Only when it has one.',
                pagination: 'The newer and older links. Only when there is more than one page.'
              }

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

    div(**part(:root, class: 'w-9/10 mx-auto my-8')) do
      articles.each do |article|
        render_article_card(article)
      end
    end

    render_pagination
  end

  private

  def render_article_card(article)
    div(**part(:card, class: 'grid gap-x-4.5 lg:grid-cols-aside-main my-4 border-b-2 border-tertiary-light')) do
      div(**part(:aside)) do
        p(**part(:published, class: 'm-0 font-bold text-right max-md:text-left max-md:pb-4'), title: article.published_at.to_s) do
          plain article_date(article.published_at, t('news.index.date_format'))
        end
      end

      div(**part(:main)) do
        h2(**part(:title, class: 'mt-0 leading-none')) { link_to article.title, news_path(article), class: 'text-foreground no-underline' }

        p(**part(:partners, class: 'text-sm')) { article_partner_links(article) } if article.partners.present?

        div(**part(:content, class: 'flex gap-x-4.5')) do
          div(**part(:body, class: 'grow-5 max-md:order-2')) do
            p { article_summary_text(article) }
          end

          if article.article_image.present?
            div(**part(:image, class: 'grow-5 max-md:order-1')) do
              image_tag article.article_image.url, class: 'border max-w-full rounded-card overflow-hidden'
            end
          end
        end

        p { UI::Button(variant: :outline, href: news_path(article), class: 'mt-4') { t('news.index.read_more') } }
      end
    end
  end

  # Both links are optional: "Recent news" only appears once you have paged
  # past the first page, "Older" only while a next page actually exists (the
  # controller knows this from fetching one extra record).
  def render_pagination
    return unless offset.positive? || has_more

    nav(**part(:pagination, class: 'p-8')) do
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
