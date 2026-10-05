# frozen_string_literal: true

class Views::Directory::Partners::Index < Views::Base
  SORT_OPTIONS = %w[recent name].freeze

  prop :partners, _Interface(:each)
  prop :pagy, _Nilable(Pagy::Offset), default: nil
  prop :site, _Nilable(::Site)
  prop :query, _Nilable(String), default: nil
  prop :categories, _Interface(:each), default: -> { [] }
  prop :partnerships_list, _Interface(:each), default: -> { [] }
  prop :neighbourhoods_tree, _Interface(:each), default: -> { [] }
  prop :selected_category, _Nilable(String), default: nil
  prop :selected_partnership, _Nilable(String), default: nil
  prop :selected_neighbourhood, _Nilable(String), default: nil
  prop :total_count, Integer, default: 0
  prop :partnership_count, Integer, default: 0
  prop :sort, String, default: 'recent'
  prop :az_letters, _Interface(:include?), default: -> { Set.new }
  prop :selected_letter, _Nilable(String), default: nil
  prop :area_labels, Hash, default: -> { {} }

  def view_template
    content_for(:title) { ::Partner.model_name.human(count: 2) }
    content_for(:description) { t('directory.partners.index.description', count: @total_count) }

    Directory::PageHero(
      title: t('directory.partners.index.hero_title'),
      kicker: kicker_text,
      subtitle: t('directory.partners.index.hero_subtitle'),
      breadcrumb_label: ::Partner.model_name.human(count: 2)
    )

    div(class: 'container-public py-6') do
      Directory::PartnerFilter(
        query: @query,
        categories: @categories,
        partnerships_list: @partnerships_list,
        neighbourhoods_tree: @neighbourhoods_tree,
        selected_category: @selected_category,
        selected_partnership: @selected_partnership,
        selected_neighbourhood: @selected_neighbourhood
      )

      render_results_header
      render_sort_tabs
      Directory::AzJumpBar(active_letters: @az_letters, selected_letter: @selected_letter, filter_params: current_filter_params) if @sort == 'name'
      render_partner_list
      Directory::Paginator(pagy: @pagy) if @pagy
    end
  end

  private

  def kicker_text
    t('directory.partners.index.kicker', count: @total_count, partnerships: @partnership_count)
  end

  def render_results_header
    filtered_total = @pagy ? @pagy.count : partner_list.size
    div(class: 'flex justify-between items-baseline flex-wrap gap-2 py-3') do
      div(class: 'text-sm text-tertiary') do
        if any_filter_active?
          plain t('directory.partners.index.results.filtered', shown: partner_list.size, total: filtered_total)
        else
          plain t('directory.partners.index.results.total', count: @total_count)
        end
        plain t('directory.partners.index.results.page', page: @pagy.page, pages: @pagy.pages) if @pagy&.pages && @pagy.pages > 1
      end
    end
  end

  def render_sort_tabs
    items = SORT_OPTIONS.map do |value|
      {
        label: t("directory.partners.index.sort.#{value}"),
        href: "#{partners_path}?#{current_filter_params.merge('sort' => value).to_query}",
        active: @sort == value
      }
    end
    Directory::ToggleTabs(items: items, aria_label: t('directory.aria.sort_order'))
  end

  def render_partner_list
    div(id: 'partner-list', class: 'lg:columns-2 gap-x-4') do
      if @sort == 'name'
        render_alphabetical_list
      else
        partner_list.each { |partner| Directory::PartnerCard(partner: partner, site: @site, area: @area_labels[partner.id]) }
      end
    end

    return unless partner_list.none?

    Directory::EmptyState(
      message: t('directory.partners.index.empty'),
      link_text: t('directory.partners.index.clear'),
      link_href: partners_path
    )
  end

  def partner_list
    @partner_list ||= Array(@partners)
  end

  def render_alphabetical_list
    current_letter = nil
    partner_list.each do |partner|
      letter = partner.name[0]&.upcase
      if letter != current_letter && letter&.match?(/[A-Z]/)
        current_letter = letter
        h2(id: "letter-#{letter}",
           class: '[column-span:all] font-serif text-2xl text-foreground mt-8 mb-3 pt-3 border-t-2 border-rules scroll-mt-4') { letter }
      end
      Directory::PartnerCard(partner: partner, site: @site, area: @area_labels[partner.id])
    end
  end

  def any_filter_active?
    @query.present? || @selected_category.present? || @selected_partnership.present? || @selected_neighbourhood.present? || @selected_letter.present?
  end

  def current_filter_params
    params = {}
    params['q'] = @query if @query.present?
    params['category'] = @selected_category if @selected_category.present?
    params['partnership'] = @selected_partnership if @selected_partnership.present?
    params['neighbourhood'] = @selected_neighbourhood if @selected_neighbourhood.present?
    params
  end
end
