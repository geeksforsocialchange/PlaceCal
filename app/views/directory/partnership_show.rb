# frozen_string_literal: true

class Views::Directory::PartnershipShow < Views::Base
  include Views::Directory::Concerns::FlattensEvents

  prop :partnership, ::Site
  prop :partners, _Interface(:each)
  prop :upcoming_events, _Interface(:each)
  prop :partner_event_counts, Hash, default: -> { {} }
  prop :event_count, Integer, default: 0
  prop :site, _Nilable(::Site), default: nil

  def view_template
    content_for(:title) { @partnership.name }
    content_for(:description) { @partnership.description.presence || "#{@partnership.name} — a PlaceCal partnership bringing together community partners and events." }

    render_hero
    div(class: 'container-public py-6') do
      div(class: 'lg:grid lg:grid-cols-[1fr_340px] lg:gap-8') do
        div do
          render_partners
          render_events
        end
        render_sidebar
      end
    end
  end

  private

  def render_hero
    section(class: 'bg-foreground', style: 'color: var(--color-background)') do
      div(class: 'container-public py-8') do
        render_breadcrumb
        div(class: 'allcaps-label mb-1 opacity-70') { 'Partnership' }
        h1(class: 'hero-title') do
          plain @partnership.name
        end
        div(class: 'text-base leading-relaxed max-w-[620px] mb-5 opacity-80') { @partnership.description } if @partnership.description.present?
        div(class: 'flex flex-col items-start gap-4 mt-2') do
          render_visit_button
          div(class: 'flex flex-wrap items-center gap-3') do
            render_stat_chips
          end
        end
      end
    end
  end

  def render_breadcrumb
    nav(class: 'text-sm mb-2', style: 'color: var(--color-background)', aria_label: 'Breadcrumb') do
      a(href: root_path, class: 'no-underline hover:underline opacity-70', style: 'color: inherit') { 'Directory' }
      span(class: 'mx-1.5 opacity-60') { safe('›') }
      a(href: partnerships_path, class: 'no-underline hover:underline opacity-70', style: 'color: inherit') { 'Partnerships' }
      span(class: 'mx-1.5 opacity-60') { safe('›') }
      span(class: 'opacity-90') { @partnership.name }
    end
  end

  def render_visit_button
    a(href: "https://#{@partnership.slug}.placecal.org",
      class: 'inline-flex items-center gap-2 bg-primary text-foreground font-bold rounded-full px-5 py-2 no-underline hover:brightness-110 transition-all') do
      raw(view_context.icon(:external_link, size: nil, css_class: 'w-4 h-4'))
      plain "Visit #{@partnership.slug}.placecal.org"
    end
  end

  def render_stat_chips
    chip("#{partner_count} #{'partner'.pluralize(partner_count)}", icon_name: :partner)
    chip("#{@event_count} #{'event'.pluralize(@event_count)} this month", icon_name: :event)
    chip(@partnership.primary_neighbourhood.name, icon_name: :neighbourhood) if @partnership.primary_neighbourhood
  end

  def chip(text, icon_name: nil)
    span(class: 'inline-flex items-center gap-1.5 text-sm font-bold rounded-full px-3 py-1', style: 'background: rgba(255,255,255,0.15); color: var(--color-background)') do
      raw(view_context.icon(icon_name, size: nil, css_class: 'w-4 h-4')) if icon_name
      plain text
    end
  end

  def render_partners
    div(class: 'py-4') do
      h2(class: 'allcaps-label text-tertiary mb-4') { 'Partners in this partnership' }
      div(class: 'grid grid-cols-1 md:grid-cols-2 gap-2') do
        displayed_partners.each do |partner|
          Directory::PartnerMini(partner: partner, event_count: @partner_event_counts[partner.id] || 0)
        end
      end
      render_see_all_button("See all #{partner_count} partners", "https://#{@partnership.slug}.placecal.org/partners")
    end
  end

  def render_events
    return if flat_events.empty?

    div(class: 'py-6') do
      h2(class: 'allcaps-label text-tertiary mb-4') { 'Upcoming events' }
      flat_events.first(10).each do |event|
        Directory::EventRow(event: event)
      end
      render_see_all_button('See all events', "https://#{@partnership.slug}.placecal.org/events")
    end
  end

  def render_see_all_button(text, href)
    div(class: 'mt-6') do
      a(href: href, class: 'btn-dark transition-colors') do
        plain text
        raw(view_context.icon(:external_link, size: nil, css_class: 'w-4 h-4'))
      end
    end
  end

  def render_sidebar
    div(class: 'hidden lg:flex lg:flex-col lg:gap-6') do
      render_map_card
      render_cta_card
    end
  end

  def render_map_card
    div(class: 'rounded-card overflow-hidden bg-home-background-3 min-h-[280px]') do
      partner_locations = partner_list.filter_map do |p|
        next unless p.address&.latitude

        { lat: p.address.latitude, lon: p.address.longitude, name: p.name, url: partner_path(p) }
      end

      if partner_locations.any?
        div(
          class: 'h-[280px]',
          data: {
            controller: 'cluster-map',
            cluster_map_markers_value: partner_locations.to_json,
            cluster_map_style_url_value: '/map-styles/pink.json'
          }
        )
      else
        div(class: 'h-[280px] flex items-center justify-center') do
          div(class: 'text-tertiary text-sm font-bold') { 'Map coming soon' }
        end
      end
    end
  end

  def render_cta_card
    coordinator = @partnership.site_admin

    div(class: 'rounded-card overflow-hidden') do
      div(class: 'bg-secondary px-4 py-3') do
        div(class: 'font-serif text-lg', style: 'color: #43392f') { 'Get involved' }
      end
      div(class: 'bg-home-background-3 px-4 py-3') do
        area_name = @partnership.primary_neighbourhood&.name
        div(class: 'text-sm text-tertiary mb-4') do
          plain "Running a community group#{" in #{area_name}" if area_name}? Join this partnership to list your events."
        end
        if coordinator
          div(class: 'mb-4') do
            div(class: 'font-bold text-sm text-foreground') { coordinator.full_name } if coordinator.full_name.present?
            if coordinator.email.present?
              a(href: "mailto:#{coordinator.email}", class: 'text-sm text-foreground underline hover:decoration-primary') do
                plain coordinator.email
              end
            end
          end
        end
        a(href: '/get-in-touch',
          class: 'btn-dark-outline transition-colors') do
          plain 'Contact coordinator'
        end
      end
    end
  end

  def partner_list
    @partner_list ||= if @partners.respond_to?(:each_pair)
                        @partners.values.flatten
                      else
                        Array(@partners)
                      end
  end

  def displayed_partners
    @displayed_partners ||= partner_list.sort_by { |p| p.updated_at || Time.zone.at(0) }.last(10).reverse
  end

  def partner_count
    partner_list.size
  end
end
