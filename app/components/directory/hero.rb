# frozen_string_literal: true

class Components::Directory::Hero < Components::Directory::Base
  prop :title, String
  prop :subtitle, _Nilable(String), default: nil
  prop :search_path, _Nilable(String), default: nil
  prop :partner_locations, _Interface(:each), default: -> { [] }
  prop :jump_neighbourhoods, _Interface(:each), default: -> { [] }

  def view_template
    section(class: 'bg-foreground py-10 lg:py-14', style: 'color: var(--color-background)') do
      div(class: 'container-public') do
        div(class: 'lg:grid lg:grid-cols-[1fr_var(--width-sidebar-lg)] lg:gap-8') do
          render_content
          render_map_placeholder
        end
      end
    end
  end

  private

  def render_content
    div(class: 'pb-6 lg:pb-10') do
      h1(class: 'hero-title') { @title }
      div(class: 'text-base leading-relaxed max-w-(--width-prose) mb-6') { @subtitle } if @subtitle
      render_search if @search_path
      render_jump_links
    end
  end

  def render_search
    form(action: @search_path, method: 'get',
         class: 'flex items-center bg-background rounded-full p-1 pl-2 max-w-(--width-search-hero) shadow-[0_0_0_2px_rgba(255,255,255,0.2)]') do
      div(class: 'px-2 text-tertiary') do
        raw(view_context.icon(:search, size: nil, css_class: 'w-[18px] h-[18px]'))
      end
      input(
        type: 'text', name: 'q',
        placeholder: t('directory.hero.search_placeholder'),
        class: 'flex-1 border-0 bg-transparent py-2 text-foreground text-detail outline-none placeholder:text-tertiary'
      )
      button(type: 'submit',
             class: 'bg-primary text-foreground rounded-full px-5 py-2 text-detail font-bold border-0 cursor-pointer hover:bg-primary/80 transition-colors') do
        plain t('directory.hero.search_button')
      end
    end
  end

  def render_jump_links
    links = jump_links
    return if links.none?

    div(class: 'flex items-center gap-6 mt-6 flex-wrap') do
      span(class: 'text-sm') { t('directory.hero.jump_to') }
      links.each do |link|
        a(href: partners_path(neighbourhood: link[:neighbourhood_id]),
          class: 'font-bold text-detail no-underline hover:underline hover:decoration-primary',
          style: 'color: inherit') { link[:name] }
      end
    end
  end

  # Each jump link points at the partners directory filtered to that place,
  # labelled with the neighbourhood name.
  def jump_links
    @jump_neighbourhoods.map do |neighbourhood|
      { name: neighbourhood.name, neighbourhood_id: neighbourhood.id }
    end
  end

  def render_map_placeholder
    div(class: 'hidden lg:block') do
      if @partner_locations.any?
        div(
          class: 'rounded-card overflow-hidden h-full',
          data: {
            controller: 'cluster-map',
            cluster_map_markers_value: @partner_locations.to_json,
            cluster_map_style_url_value: '/map-styles/pink.json'
          }
        )
      else
        div(class: 'bg-primary/20 rounded-tl-card h-full min-h-(--height-map-lg) flex items-center justify-center') do
          div(class: 'text-foreground/40 text-sm font-bold') { t('directory.map_coming_soon') }
        end
      end
    end
  end
end
