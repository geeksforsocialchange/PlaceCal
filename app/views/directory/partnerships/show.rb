# frozen_string_literal: true

class Views::Directory::Partnerships::Show < Views::Base
  include Views::Directory::Concerns::FlattensEvents

  prop :partnership, ::Site
  prop :partners, _Interface(:each)
  prop :upcoming_events, _Interface(:each)
  prop :partner_event_counts, Hash, default: -> { {} }
  prop :event_count, Integer, default: 0
  prop :site, _Nilable(::Site), default: nil

  def view_template
    content_for(:title) { @partnership.name }
    content_for(:image) { partnership_og_image_url(@partnership) }
    content_for(:image_alt) { t('og_image.alt.partnership', name: @partnership.name) }
    content_for(:description) { @partnership.description.presence || "#{@partnership.name} — a PlaceCal partnership bringing together community partners and events." }

    Directory::PageHero(
      title: @partnership.name,
      kicker: t('directory.partnerships.show.kicker'),
      subtitle: @partnership.description.presence,
      breadcrumb_label: Partnership.model_name.human(count: 2),
      breadcrumb_path: partnerships_path,
      background_image_url: hero_image_url
    ) do
      div(class: 'flex flex-col items-start gap-4 mt-4') do
        render_visit_button
        div(class: 'flex flex-wrap items-center gap-3 mb-2') do
          render_stat_chips
        end
      end
    end

    div(class: 'container-public py-6') do
      div(class: 'lg:grid lg:grid-cols-[1fr_var(--width-sidebar)] lg:gap-8') do
        div do
          render_partners
          render_events
        end
        render_sidebar
      end
    end
  end

  private

  def render_visit_button
    href = @partnership.url.presence || "https://#{@partnership.slug}.placecal.org"
    display_url = href.sub(%r{\Ahttps?://}, '').chomp('/')
    a(href: href,
      class: 'inline-flex items-center gap-2 bg-primary text-foreground font-bold rounded-full px-5 py-2 no-underline hover:brightness-110 transition-all') do
      raw(view_context.icon(:external_link, size: nil, css_class: 'w-4 h-4'))
      plain t('directory.partnerships.show.visit', url: display_url)
    end
  end

  def render_stat_chips
    chip("#{partner_count} #{Partner.model_name.human(count: partner_count).downcase}", icon_name: :partner)
    chip(t('directory.partnerships.show.events_this_month', count: @event_count), icon_name: :event)
    chip(@partnership.primary_neighbourhood.name, icon_name: :neighbourhood) if @partnership.primary_neighbourhood
  end

  def chip(text, icon_name: nil)
    span(class: 'inline-flex items-center gap-1.5 text-sm font-bold rounded-full px-3 py-1', style: 'background: rgba(255,255,255,0.15); color: var(--color-background)') do
      raw(view_context.icon(icon_name, size: nil, css_class: 'w-4 h-4')) if icon_name
      plain text
    end
  end

  def render_partners
    div(class: 'pt-4 pb-8') do
      h2(class: 'allcaps-label text-tertiary mb-4') { t('directory.partnerships.show.partners_heading') }
      div(class: 'grid grid-cols-1 md:grid-cols-2 gap-x-6') do
        displayed_partners.each do |partner|
          Directory::PartnerMini(partner: partner, event_count: @partner_event_counts[partner.id] || 0)
        end
      end
      render_see_all_button(t('directory.partnerships.show.see_all_partners', count: partner_count), "#{partnership_base_url}/partners")
    end
  end

  def render_events
    return if flat_events.empty?

    div(class: 'py-6') do
      h2(class: 'allcaps-label text-tertiary mb-4') { t('directory.partnerships.show.upcoming_events') }
      flat_events.first(10).each do |event|
        Directory::EventRow(event: event)
      end
      render_event_overflow(flat_events.drop(10))
      render_see_all_button(t('directory.partnerships.show.see_all_events'), "#{partnership_base_url}/events")
    end
  end

  def render_event_overflow(remaining)
    return if remaining.empty?

    batch = remaining.first(10)
    rest = remaining.drop(10)
    details(class: 'group') do
      summary(class: 'list-none pt-3 border-t border-rules cursor-pointer [&::-webkit-details-marker]:hidden') do
        span(class: 'inline-flex items-center gap-1.5 text-sm font-bold text-foreground group-open:hidden') do
          plain t('directory.partnerships.show.show_more_events', count: [10, remaining.size].min)
          span(class: 'text-tertiary') { safe('&#9660;') }
        end
      end
      batch.each do |event|
        Directory::EventRow(event: event)
      end
      render_event_overflow(rest)
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

  def hero_image_url
    @partnership.hero_image.standard.url if @partnership.read_attribute(:hero_image).present?
  end

  def render_map_card
    div(class: 'rounded-card overflow-hidden bg-home-background-3') do
      partner_locations = partner_list.filter_map do |p|
        next unless p.address&.latitude

        { lat: p.address.latitude, lon: p.address.longitude, name: p.name, url: partner_path(p) }
      end

      if partner_locations.any?
        div(
          class: 'h-(--height-map-lg)',
          data: {
            controller: 'cluster-map',
            cluster_map_markers_value: partner_locations.to_json,
            cluster_map_style_url_value: '/map-styles/pink.json'
          }
        )
      else
        div(class: 'h-(--height-map) flex items-center justify-center') do
          div(class: 'text-tertiary text-sm font-bold') { t('directory.map_coming_soon') }
        end
      end
    end
  end

  def render_cta_card
    coordinator = @partnership.site_admin

    div(class: 'rounded-card overflow-hidden') do
      div(class: 'bg-secondary px-4 py-3') do
        div(class: 'font-serif text-lg', style: 'color: #43392f') { t('directory.partnerships.show.get_involved') }
      end
      div(class: 'bg-home-background-3 px-4 py-3') do
        area_name = @partnership.primary_neighbourhood&.name
        area = area_name ? t('directory.partnerships.show.cta_area', name: area_name) : ''
        div(class: 'text-sm text-tertiary mb-4') do
          plain t('directory.partnerships.show.cta_text', area: area)
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
        contact_href = coordinator&.email.present? ? "mailto:#{coordinator.email}" : '/get-in-touch'
        a(href: contact_href,
          class: 'btn-dark-outline transition-colors') do
          plain t('directory.partnerships.show.contact_coordinator')
        end
      end
    end
  end

  def partnership_base_url
    @partnership_base_url ||= @partnership.url.presence || "https://#{@partnership.slug}.placecal.org"
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
