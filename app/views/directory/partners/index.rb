# frozen_string_literal: true

class Views::Directory::Partners::Index < Views::Base
  prop :partners, _Interface(:each)
  prop :pagy, _Nilable(Pagy::Offset), default: nil
  prop :site, ::Site
  prop :query, _Nilable(String), default: nil
  prop :categories, _Interface(:each), default: -> { [] }
  prop :partnerships_list, _Interface(:each), default: -> { [] }
  prop :neighbourhoods, _Interface(:each), default: -> { [] }
  prop :selected_category, _Nilable(String), default: nil
  prop :selected_partnership, _Nilable(String), default: nil
  prop :selected_neighbourhood, _Nilable(String), default: nil
  prop :total_count, Integer, default: 0
  prop :partnership_count, Integer, default: 0
  prop :sort, String, default: 'recent'
  prop :az_letters, _Interface(:include?), default: -> { Set.new }
  prop :selected_letter, _Nilable(String), default: nil

  def view_template
    content_for(:title) { 'Partners' }
    content_for(:description) { "Browse #{@total_count} community partners across the UK on PlaceCal. Search by name, category, partnership or neighbourhood." }

    Directory::PageHero(
      title: 'All partners on PlaceCal',
      kicker: kicker_text,
      subtitle: 'Every community group, venue, library and organisation publishing their events on PlaceCal, UK-wide.',
      breadcrumb_label: 'Partners'
    )

    div(class: 'container-public py-6') do
      Directory::PartnerFilter(
        query: @query,
        categories: @categories,
        partnerships_list: @partnerships_list,
        neighbourhoods: @neighbourhoods,
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
    "#{@total_count} partners across #{@partnership_count} partnerships"
  end

  def render_results_header
    filtered_total = @pagy ? @pagy.count : partner_list.size
    div(class: 'flex justify-between items-baseline flex-wrap gap-2 py-3') do
      div(class: 'text-sm text-tertiary') do
        if any_filter_active?
          plain "Showing #{partner_list.size} of #{filtered_total} partners"
        else
          plain "#{@total_count} partners"
        end
        plain " — page #{@pagy.page} of #{@pagy.pages}" if @pagy&.pages && @pagy.pages > 1
      end
    end
  end

  def render_sort_tabs
    nav(class: 'flex gap-1 flex-wrap py-2', aria_label: 'Sort order') do
      [['Recently updated', 'recent'], ['A–Z', 'name']].each do |label, value|
        sort_params = current_filter_params.merge('sort' => value)
        if @sort == value
          span(class: 'inline-flex items-center px-4 py-1.5 rounded-full text-sm font-bold bg-foreground text-background') { label }
        else
          a(href: "#{partners_path}?#{sort_params.to_query}",
            class: 'inline-flex items-center px-4 py-1.5 rounded-full text-sm font-bold bg-home-background-3 text-foreground no-underline hover:bg-primary transition-colors') do
            plain label
          end
        end
      end
    end
  end

  def render_partner_list
    div(id: 'partner-list', class: 'lg:columns-2 gap-x-4') do
      if @sort == 'name'
        render_alphabetical_list
      else
        partner_list.each { |partner| Directory::PartnerCard(partner: partner, site: @site) }
      end
    end

    return unless partner_list.none?

    div(class: 'py-10 text-center') do
      p(class: 'text-tertiary text-lg') { 'No partners found matching your filters.' }
      a(href: partners_path, class: 'inline-flex items-center gap-2 mt-3 text-foreground font-bold no-underline hover:underline') do
        plain 'Clear filters'
      end
    end
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
      Directory::PartnerCard(partner: partner, site: @site)
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
