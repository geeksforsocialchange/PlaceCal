# frozen_string_literal: true

class Views::Directory::News::Index < Views::Base
  prop :articles, _Interface(:each)
  prop :pagy, Pagy::Offset
  prop :partner, _Nilable(::Partner), default: nil
  # Area breadcrumbs keyed by partner id (PartnersQuery.area_labels)
  prop :area_labels, Hash, default: -> { {} }

  def view_template
    content_for(:title) { hero_title }
    content_for(:description) { t('directory.news.index.description') }
    content_for(:rss_feed) { rss_feed_path }

    Directory::PageHero(
      title: hero_title,
      kicker: kicker,
      subtitle: t('directory.news.index.hero_subtitle'),
      breadcrumb_label: t('navigation.news')
    )

    div(class: 'container-public py-6') do
      article_list.each do |article|
        Directory::NewsRow(
          article: article,
          summary: true,
          area: area_label_for(article)
        )
      end

      render_empty_state if article_list.empty?

      Directory::Paginator(pagy: @pagy)

      p(class: 'mt-6 text-sm') do
        link_to t('directory.news.index.rss'), rss_feed_path,
                class: 'with-no-sass text-tertiary underline decoration-primary decoration-2 underline-offset-2 hover:text-foreground'
      end
    end
  end

  private

  def article_list
    @article_list ||= @articles.to_a
  end

  def hero_title
    if @partner
      t('news.index.title_for_partner', partner: @partner.name)
    else
      t('directory.news.index.hero_title')
    end
  end

  def kicker
    kicker = t('directory.news.index.results.total', count: @pagy.count)
    kicker += t('directory.news.index.results.page', page: @pagy.page, pages: @pagy.pages) if @pagy.pages > 1
    kicker
  end

  def area_label_for(article)
    partner = article.partners.first
    partner && @area_labels[partner.id]
  end

  def rss_feed_path
    news_index_path(**{ format: :rss, partner: @partner&.slug }.compact)
  end

  def render_empty_state
    Directory::EmptyState(
      message: t('directory.news.index.empty'),
      link_text: (t('directory.filters.clear') if @partner),
      link_href: (news_index_path if @partner)
    )
  end
end
