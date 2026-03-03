# frozen_string_literal: true

class Views::News::Index < Views::Base
  register_output_helper :article_partner_links
  register_value_helper :article_summary_text

  prop :articles, _Any, reader: :private
  prop :site, _Any, reader: :private
  prop :next_offset, _Any, reader: :private

  def view_template
    content_for(:title) { 'News from your area' }

    render(Components::Hero.new('News from your area', site.tagline))

    div(class: 'articles') do
      articles.each do |article|
        render_article_card(article)
      end
    end

    p(class: 'articles__pagination') do
      link_to 'Older news items', "?offset=#{next_offset}" if articles.count == NewsController::ARTICLES_PER_PAGE
    end
  end

  private

  def render_article_card(article) # rubocop:disable Metrics/AbcSize
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

        p { link_to 'Find out more', news_path(article), class: 'btn btn--alt btn--mt' }
      end
    end
  end
end
