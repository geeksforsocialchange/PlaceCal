# frozen_string_literal: true

class Views::Directory::Partners::Show < Views::Partners::Show
  def view_template
    set_content_for_tags

    Directory::PageHero(
      title: partner.name,
      kicker: partner_location_kicker,
      breadcrumb_label: 'Partners',
      breadcrumb_path: partners_path
    )

    div(class: 'container-public py-6') do
      div(class: 'lg:grid lg:grid-cols-[1fr_340px] lg:gap-8') do
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
      h2(class: 'udl udl--fw allcaps text-xl') { 'Upcoming events' }
      displayed = flat.first(10)
      remaining = flat.drop(10)
      displayed.each do |event|
        Directory::EventRow(event: event, context_partner: partner)
      end
      if remaining.any?
        details(class: 'group') do
          summary(class: 'list-none pt-3 border-t border-rules cursor-pointer [&::-webkit-details-marker]:hidden') do
            span(class: 'inline-flex items-center gap-1.5 text-sm font-bold text-foreground group-open:hidden') do
              plain "Show #{remaining.size} more events"
              span(class: 'text-tertiary') { safe('&#9660;') }
            end
          end
          remaining.each do |event|
            Directory::EventRow(event: event, context_partner: partner)
          end
        end
      end
    end
  end

  def render_directory_location
    return unless partner.address || map || partner.has_service_areas?

    div(class: 'py-4') do
      h2(class: 'udl udl--fw allcaps text-xl') { 'Location' }
      p(class: 'text-sm text-tertiary mb-3') { "Serves #{partner_service_area_text(partner)}." } if partner.has_service_areas?
      div(class: 'grid grid-cols-[1fr_auto] gap-4 items-start') do
        Map(points: map, site: site.slug, compact: true) if map
        if partner.address
          div(class: 'text-base text-foreground') do
            Address(address: partner.address)
          end
        end
      end
    end
  end

  def render_directory_accessibility
    return if partner.accessibility_info_html.blank?

    div(class: 'py-4') do
      render_accessibility_details(summary_class: 'cursor-pointer font-extra-bold text-foreground')
    end
  end

  def partner_location_kicker
    path = if partner.address&.neighbourhood
             partner.address.neighbourhood.path
           elsif partner.service_area_neighbourhoods.any?
             partner.service_area_neighbourhoods.first.path
           end
    return 'Partner' unless path&.any?

    path.last(3).map(&:name).join(' › ')
  end
end
