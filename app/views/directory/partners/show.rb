# frozen_string_literal: true

class Views::Directory::Partners::Show < Views::Partners::Show
  def view_template
    set_content_for_tags

    Directory::PageHero(
      title: partner.name,
      kicker: partner_location_kicker,
      breadcrumb_label: Partner.model_name.human(count: 2),
      breadcrumb_path: partners_path
    )

    div(class: 'container-public py-6') do
      div(class: 'lg:grid lg:grid-cols-[1fr_var(--width-sidebar)] lg:gap-8') do
        div do
          render_directory_about
          render_directory_events
          render_directory_location
          render_directory_accessibility
        end
        Directory::PartnerSidebar(partner: partner, containing_sites: containing_sites || [])
      end
    end
  end

  private

  def render_directory_about
    render_partner_description
  end

  def render_directory_events
    flat = events.respond_to?(:values) ? events.values.flatten : Array(events)
    return unless flat.any?

    div(class: 'py-4') do
      h2(class: 'udl udl--fw allcaps text-xl') { t('directory.partners.show.upcoming_events') }
      flat.first(10).each do |event|
        Directory::EventRow(event: event, context_partner: partner)
      end
      render_event_overflow(flat.drop(10))
    end
  end

  def render_event_overflow(remaining)
    return if remaining.empty?

    batch = remaining.first(10)
    rest = remaining.drop(10)
    details(class: 'group') do
      summary(class: 'list-none pt-3 border-t border-rules cursor-pointer [&::-webkit-details-marker]:hidden') do
        span(class: 'inline-flex items-center gap-1.5 text-sm font-bold text-foreground group-open:hidden') do
          plain t('directory.partners.show.show_more_events', count: [10, remaining.size].min)
          span(class: 'text-tertiary') { safe('&#9660;') }
        end
      end
      batch.each do |event|
        Directory::EventRow(event: event, context_partner: partner)
      end
      render_event_overflow(rest)
    end
  end

  def render_directory_location
    return unless partner.address || map || partner.has_service_areas?

    div(class: 'py-4') do
      h2(class: 'udl udl--fw allcaps text-xl') { t('directory.partners.show.location') }
      p(class: 'mb-3') { t('directory.partners.show.serves', area: partner_service_area_text(partner)) } if partner.has_service_areas?
      div(class: 'grid grid-cols-[1fr_auto] gap-4 items-start') do
        Map(points: map, site: site.slug, compact: true) if map
        Address(address: partner.address) if partner.address
      end
    end
  end

  def render_directory_accessibility
    return if partner.accessibility_info_html.blank?

    div(class: 'py-4') do
      h2(class: 'udl udl--fw allcaps text-xl') { t('directory.partners.show.accessibility_info') }
      div do
        raw safe(partner.accessibility_info_html.to_s)
      end
    end
  end

  def partner_location_kicker
    path = if partner.address&.neighbourhood
             partner.address.neighbourhood.path
           elsif partner.service_area_neighbourhoods.any?
             partner.service_area_neighbourhoods.first.path
           end
    return t('directory.partners.show.kicker_fallback') unless path&.any?

    path.last(3).map(&:name).join(' › ')
  end
end
