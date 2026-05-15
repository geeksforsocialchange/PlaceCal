# frozen_string_literal: true

# TODO(#3163): Move to app/directory/views/partners/index.rb
class Views::Partners::DirectoryIndex < Views::Base
  prop :partners, _Interface(:each)
  prop :pagy, Pagy::Offset
  prop :site, ::Site
  prop :query, _Nilable(String), default: nil
  prop :categories, _Interface(:each), default: -> { [] }
  prop :partnerships_list, _Interface(:each), default: -> { [] }
  prop :neighbourhoods, _Interface(:each), default: -> { [] }
  prop :selected_category, _Nilable(String), default: nil
  prop :selected_partnership, _Nilable(String), default: nil
  prop :selected_neighbourhood, _Nilable(String), default: nil
  prop :total_count, Integer, default: 0

  def view_template
    content_for(:title) { 'Partners' }
    content_for(:description) { "Browse #{@total_count} community partners across the UK on PlaceCal. Search by name, category, partnership or neighbourhood." }

    DirectoryPageHero(
      title: 'All partners on PlaceCal',
      kicker: kicker_text,
      subtitle: 'Every community group, venue, library and organisation publishing their events on PlaceCal, UK-wide.',
      breadcrumb_label: 'Partners'
    )

    div(class: 'container-public py-6') do
      DirectoryPartnerFilter(
        query: @query,
        categories: @categories,
        partnerships_list: @partnerships_list,
        neighbourhoods: @neighbourhoods,
        selected_category: @selected_category,
        selected_partnership: @selected_partnership,
        selected_neighbourhood: @selected_neighbourhood
      )

      render_results_header
      AzJumpBar(active_letters: active_letters)
      render_partner_list
      DirectoryPaginator(pagy: @pagy)
    end
  end

  private

  def kicker_text
    partnership_count = Site.where(is_published: true).where.not(slug: 'default-site').count
    "#{@total_count} partners across #{partnership_count} partnerships"
  end

  def render_results_header
    filtered_count = @pagy.count
    div(class: 'flex justify-between items-baseline flex-wrap gap-2 py-3') do
      div(class: 'text-sm text-tertiary') do
        if any_filter_active?
          plain "Showing #{filtered_count} of #{@total_count} partners"
        else
          plain "#{@total_count} partners"
        end
        plain " — page #{@pagy.page} of #{@pagy.pages}" if @pagy.pages > 1
      end
    end
  end

  def render_partner_list
    current_letter = nil
    div(id: 'partner-list') {} # rubocop:disable Lint/EmptyBlock
    partner_list.each do |partner|
      letter = partner.name[0]&.upcase
      if letter != current_letter && letter&.match?(/[A-Z]/)
        current_letter = letter
        h3(id: "letter-#{letter}",
           class: 'font-serif text-xl text-foreground mt-6 mb-2 pt-2 border-t-2 border-rules') { letter }
      end
      DirectoryPartnerCard(partner: partner, site: @site)
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

  def active_letters
    @active_letters ||= partner_list.each_with_object(Set.new) do |partner, set|
      letter = partner.name[0]&.upcase
      set << letter if letter&.match?(/[A-Z]/)
    end
  end

  def any_filter_active?
    @query.present? || @selected_category.present? || @selected_partnership.present? || @selected_neighbourhood.present?
  end
end
