# frozen_string_literal: true

class Views::Directory::PartnershipsIndex < Views::Base
  prop :partnerships, _Interface(:each)
  prop :site, _Nilable(::Site), default: nil
  prop :query, _Nilable(String), default: nil
  prop :total_partners, Integer, default: 0

  def view_template
    content_for(:title) { 'Partnerships' }
    content_for(:description) { "Explore #{partnership_list.size} partnerships serving #{@total_partners} partners on PlaceCal." }

    Directory::PageHero(
      title: 'Partnerships on PlaceCal',
      kicker: "#{partnership_list.size} partnerships · serving #{@total_partners} partners",
      subtitle: 'A partnership is a group of community organisations working together on a local PlaceCal site. Each has its own subdomain with a hyperlocal version of the calendar.',
      breadcrumb_label: 'Partnerships'
    )

    div(class: 'container-public py-6') do
      render_search
      div(class: 'grid md:grid-cols-2 lg:grid-cols-3 gap-4') do
        filtered_partnerships.each do |partnership|
          Directory::PartnershipCard(partnership: partnership)
        end
      end
      render_empty_state if filtered_partnerships.empty?
    end
  end

  private

  def render_search
    form(action: partnerships_path, method: 'get',
         class: 'mb-6') do
      div(class: 'flex items-center bg-home-background-3 rounded-full p-1 pl-2 max-w-[440px]') do
        div(class: 'px-2 text-tertiary') do
          raw(safe('<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><line x1="16.5" y1="16.5" x2="21" y2="21"/></svg>'))
        end
        input(
          type: 'text', name: 'q', value: @query,
          placeholder: 'Search partnerships…',
          class: 'flex-1 border-0 bg-transparent py-2 text-foreground text-sm outline-none placeholder:text-tertiary'
        )
        button(type: 'submit',
               class: 'bg-foreground text-background rounded-full px-4 py-1.5 text-sm font-bold border-0 cursor-pointer hover:bg-tertiary transition-colors') do
          plain 'Search'
        end
      end
    end
  end

  def render_empty_state
    div(class: 'py-10 text-center') do
      p(class: 'text-tertiary text-lg') { 'No partnerships found.' }
      if @query.present?
        a(href: partnerships_path, class: 'inline-flex items-center gap-2 mt-3 text-foreground font-bold no-underline hover:underline') do
          plain 'Clear search'
        end
      end
    end
  end

  def partnership_list
    @partnership_list ||= Array(@partnerships)
  end

  def filtered_partnerships
    @filtered_partnerships ||= if @query.present?
                                 q = @query.downcase
                                 partnership_list.select { |p| p.name.downcase.include?(q) || p.description&.downcase&.include?(q) }
                               else
                                 partnership_list
                               end
  end
end
