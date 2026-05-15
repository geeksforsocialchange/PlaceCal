# frozen_string_literal: true

class Components::Directory::Hero < Components::Directory::Base
  prop :title, String
  prop :subtitle, _Nilable(String), default: nil
  prop :search_path, _Nilable(String), default: nil
  prop :partner_locations, _Interface(:each), default: -> { [] }

  def view_template
    section(class: 'bg-foreground py-10 lg:py-14', style: 'color: var(--color-background)') do
      div(class: 'container-public') do
        div(class: 'lg:grid lg:grid-cols-[1.1fr_1fr] lg:gap-10 lg:items-center') do
          render_content
          render_map_placeholder
        end
      end
    end
  end

  private

  def render_content
    div(class: 'pb-6 lg:pb-10') do
      h1(class: 'font-serif font-regular text-hero leading-hero mb-3') { @title }
      p(class: 'text-base leading-relaxed max-w-[620px] mb-6 opacity-90') { @subtitle } if @subtitle
      render_search if @search_path
      render_jump_links
    end
  end

  def render_search
    form(action: @search_path, method: 'get',
         class: 'flex items-center bg-white rounded-full p-1 pl-2 max-w-[540px] shadow-[0_0_0_2px_rgba(255,255,255,0.2)]') do
      div(class: 'px-2 text-tertiary') do
        raw(safe('<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><line x1="16.5" y1="16.5" x2="21" y2="21"/></svg>'))
      end
      input(
        type: 'text', name: 'q',
        placeholder: 'Search a town, partner, or organisation…',
        class: 'flex-1 border-0 bg-transparent py-2 text-foreground text-detail outline-none placeholder:text-tertiary'
      )
      button(type: 'submit',
             class: 'bg-primary text-foreground rounded-full px-5 py-2 text-detail font-bold border-0 cursor-pointer hover:bg-primary/80 transition-colors') do
        plain 'Search'
      end
    end
  end

  def render_jump_links
    div(class: 'flex items-center gap-6 mt-6 flex-wrap') do
      span(class: 'text-background/85 text-sm') { 'Jump to:' }
      %w[Manchester Tameside Salford London].each do |area|
        a(href: partners_path(q: area),
          style: 'color: var(--color-background); text-decoration: none;',
          class: 'font-bold text-detail hover:underline hover:decoration-primary') { area }
      end
    end
  end

  def render_map_placeholder
    div(class: 'hidden lg:block self-stretch -mb-10 -mr-10') do
      if @partner_locations.any?
        div(
          class: 'rounded-card h-full min-h-[360px] overflow-hidden',
          data: {
            controller: 'cluster-map',
            cluster_map_markers_value: @partner_locations.to_json,
            cluster_map_style_url_value: '/map-styles/pink.json'
          }
        )
      else
        div(class: 'bg-primary/20 rounded-tl-card h-full min-h-[360px] flex items-center justify-center') do
          p(class: 'text-foreground/40 text-sm font-bold') { 'Map coming soon' }
        end
      end
    end
  end
end
