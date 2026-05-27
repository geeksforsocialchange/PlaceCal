# frozen_string_literal: true

class Views::Partners::Show < Views::Base
  register_value_helper :partner_service_area_text

  prop :partner, Partner, reader: :private
  prop :site, Site, reader: :private
  prop :current_day, Date, reader: :private
  prop :map, _Nilable(Array), reader: :private
  prop :events, _Interface(:each), reader: :private
  prop :period, _Nilable(String), reader: :private
  prop :sort, _Nilable(String), reader: :private
  prop :repeating, _Nilable(String), reader: :private
  prop :no_event_message, _Nilable(String), reader: :private
  prop :paginator, _Nilable(_Boolean), reader: :private
  prop :date_period, _Nilable(String), reader: :private, default: nil
  prop :show_monthly, _Boolean, reader: :private, default: true
  prop :containing_sites, _Nilable(_Interface(:each)), reader: :private, default: nil

  def view_template
    content_for(:title) { partner.name }
    if partner.image.present?
      content_for(:image) { partner.image }
    else
      content_for(:image) { site.og_image }
    end
    content_for(:description) { partner.summary } if partner.summary
    content_for(:json_ld) { safe(partner.to_json_ld(base_url: request.base_url).to_json) }

    if site.default_site?
      render_directory_layout
    else
      render_local_layout
      render_meta_section
    end
  end

  private

  # ── Directory layout (default site) ──

  def render_directory_layout
    Directory::PageHero(
      title: partner.name,
      kicker: partner.categories.first&.name || 'Partner',
      breadcrumb_label: 'Partners'
    )

    div(class: 'container-public py-6') do
      div(class: 'lg:grid lg:grid-cols-[1fr_340px] lg:gap-8') do
        div do
          render_directory_about
          render_directory_events
          render_directory_location
          render_directory_accessibility
        end
        render_directory_sidebar
      end
    end
  end

  def render_directory_about
    if partner.summary
      div(class: 'p--big') do
        content_tag(:p, partner.summary)
      end
    end
    return if partner.description_html.blank?

    div do
      raw safe(partner.description_html.to_s)
    end
  end

  def render_directory_events
    flat = events.respond_to?(:values) ? events.values.flatten : Array(events)
    return unless flat.any?

    div(class: 'py-4') do
      h2(class: 'udl udl--fw allcaps h4') { 'Upcoming events' }
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
      h2(class: 'udl udl--fw allcaps h4') { 'Location' }
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

  def render_directory_sidebar
    div(class: 'flex flex-col gap-4') do
      render_sidebar_image if partner.read_attribute(:image).present?
      render_sidebar_partnerships if containing_sites&.any?
      render_sidebar_contact if directory_contact?
      render_sidebar_opening_times if partner.human_readable_opening_times.any?
      render_sidebar_categories if partner.categories.any?
      render_sidebar_neighbourhood if partner.address&.neighbourhood
      render_sidebar_share
    end
  end

  def render_sidebar_partnerships
    count = Array(containing_sites).size
    div(class: 'rounded-card overflow-hidden') do
      div(class: 'bg-foreground px-4 py-3', style: 'color: var(--color-background)') do
        div(class: 'allcaps-label mb-0.5 opacity-80') { 'Part of' }
        div(class: 'font-serif text-lg') { "#{count} #{'partnership'.pluralize(count)}" }
      end
      div(class: 'bg-home-background-3 px-4 py-3') do
        div(class: 'text-xs text-tertiary mb-3') do
          plain "You can find #{partner.name} on these local PlaceCal sites:"
        end
        Array(containing_sites).each do |site_record|
          a(href: "https://#{site_record.slug}.placecal.org",
            class: 'flex items-center justify-between py-2 no-underline text-foreground hover:bg-background/50 transition-colors rounded px-1') do
            div do
              div(class: 'font-extra-bold text-sm') { site_record.name }
              div(class: 'text-xs text-tertiary') do
                plain site_record.primary_neighbourhood&.name if site_record.primary_neighbourhood
              end
            end
            span(class: 'text-tertiary') { safe('&#8599;') }
          end
        end
      end
    end
  end

  def render_sidebar_categories
    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      h3(class: 'allcaps-label text-tertiary mb-2') { 'Categories' }
      div(class: 'flex flex-wrap gap-1.5') do
        partner.categories.each do |cat|
          a(href: partners_path(category: cat.id),
            class: 'inline-flex items-center bg-primary text-foreground text-2xs font-bold rounded-full px-2.5 py-0.5 no-underline hover:brightness-110 transition-colors') do
            plain cat.name
          end
        end
      end
    end
  end

  def render_sidebar_neighbourhood
    neighbourhood = partner.address.neighbourhood
    path = neighbourhood.path

    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      h3(class: 'allcaps-label text-tertiary mb-2') { 'Neighbourhood' }
      div(class: 'flex flex-wrap items-center gap-1 text-sm') do
        path.each_with_index do |ancestor, i|
          span(class: 'text-tertiary mx-0.5') { safe('&rsaquo;') } if i.positive?
          if ancestor == neighbourhood
            span(class: 'font-extra-bold text-foreground') { ancestor.name }
          else
            span(class: 'text-foreground') { ancestor.name }
          end
        end
      end
    end
  end

  def render_sidebar_share
    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      div(class: 'allcaps-label text-tertiary mb-3') { 'Share & subscribe' }

      div do
        a(href: "https://placecal.org/partners/#{partner.slug}",
          class: 'font-mono text-sm text-foreground break-all no-underline hover:underline hover:decoration-primary') do
          plain "placecal.org/partners/#{partner.slug}"
        end
      end
      div(class: 'mt-3') do
        a(href: partner_url(partner, protocol: :webcal, format: :ics),
          class: 'inline-flex items-center gap-1.5 text-sm font-bold text-foreground no-underline hover:underline hover:decoration-primary') do
          raw(safe('<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>'))
          plain 'Subscribe via iCal'
        end
      end
    end
  end

  def render_sidebar_image
    div(class: 'rounded-card overflow-hidden') do
      img(
        src: partner.image.standard.url,
        srcset: "#{partner.image.standard.url} 1x, #{partner.image.retina.url} 2x",
        alt: partner.name,
        class: 'w-full object-cover'
      )
    end
  end

  def render_sidebar_contact
    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      h3(class: 'allcaps-label text-tertiary mb-3') { 'Get in touch' }
      div(class: 'flex flex-col gap-2') do
        render_contact_row(:contact_phone, partner.public_phone, "tel:#{partner.public_phone}") if partner.public_phone.present?
        render_contact_row(:contact_email, partner.public_email, "mailto:#{partner.public_email}") if partner.public_email.present?
        render_contact_row(:contact_website, strip_url(partner.url), partner.url) if partner.url.present?
        render_contact_row(:contact_facebook, 'Facebook', "https://facebook.com/#{partner.facebook_link}") if partner.facebook_link.present?
        render_contact_row(:contact_twitter, "@#{partner.twitter_handle}", "https://twitter.com/#{partner.twitter_handle}") if partner.twitter_handle.present?
        render_contact_row(:contact_instagram, "@#{partner.instagram_handle}", "https://www.instagram.com/#{partner.instagram_handle}/") if partner.instagram_handle.present?
      end
    end
  end

  def render_contact_row(icon_name, label, href)
    a(href: href, target: '_blank', rel: 'noopener',
      class: 'flex items-center gap-2.5 text-sm text-foreground no-underline hover:underline hover:decoration-primary') do
      raw(view_context.icon(icon_name, size: '4'))
      span(class: 'truncate') { label }
    end
  end

  def render_sidebar_opening_times
    times = partner.human_readable_opening_times
    return unless times.any?

    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      h3(class: 'allcaps-label text-tertiary mb-3') { 'Opening times' }
      ul(class: 'text-sm text-foreground space-y-1 list-none pl-0') do
        times.each { |slot| li { slot } }
      end
    end
  end

  def render_directory_accessibility
    return if partner.accessibility_info_html.blank?

    div(class: 'py-4') do
      details(id: 'accessibility-info') do
        summary(class: 'cursor-pointer font-extra-bold text-foreground') { 'Accessibility information' }
        div(class: 'mt-2 text-sm text-foreground') do
          raw safe(partner.accessibility_info_html.to_s)
        end
      end
    end
  end

  def directory_contact?
    partner.public_phone.present? || partner.public_email.present? || partner.url.present? ||
      partner.facebook_link.present? || partner.twitter_handle.present? || partner.instagram_handle.present?
  end

  def strip_url(target_url)
    target_url.gsub('http://', '').gsub('https://', '').gsub('www.', '').gsub(%r{/$}, '')
  end

  # ── Local site layout ──

  def render_local_layout
    div do
      Hero(partner.name, site.tagline)

      div(class: 'container-public mb-32') do
        Breadcrumb(
          trail: [['Partners', partners_path], [partner.name, partner_path(partner)]],
          site_name: site.name
        )

        render_partner_details
        render_managees
        render_events_section
      end
    end
  end

  def render_partner_details
    div(class: 'g g--partner') do
      div(class: 'gi gi__3-5') do
        render_partner_description
        render_contact_and_address
      end
      div(class: 'gi gi__2-5') do
        render_partner_image
        Map(points: map, site: site.slug, compact: true)
        render_opening_times
      end
    end
  end

  def render_partner_description
    return unless partner.summary

    div(class: 'p--big') do
      content_tag(:p, partner.summary)
    end
    return if partner.description_html.blank?

    div do
      raw safe(partner.description_html.to_s)
    end
  end

  def render_contact_and_address
    h3(class: 'udl udl--fw allcaps h4') { 'Get in touch' }
    ContactDetails(partner: partner)

    h3(class: 'udl udl--fw allcaps h4') { 'Address' }
    p { "We operate in #{partner_service_area_text(partner)}." } if partner.has_service_areas?

    Address(address: partner.address)

    if partner.accessibility_info_html.present?
      details(id: 'accessibility-info') do
        summary { 'Accessibility information' }
        raw safe(partner.accessibility_info_html.to_s)
      end
    end

    return unless partner.managees.any?

    p(class: 'small') do
      plain "#{partner.name} manage "
      raw safe_join(partner.managees.map { |place| link_to place.name, place }, ', ')
      plain '.'
    end
  end

  def render_partner_image
    return unless partner.image?

    div(class: 'gi__image') do
      img(
        src: partner.image.standard.url,
        srcset: "#{partner.image.standard.url} 1x, #{partner.image.retina.url} 2x",
        alt: "Image for #{partner.name}",
        class: 'map--single'
      )
    end
  end

  def render_opening_times
    times = partner.human_readable_opening_times
    return unless times.any?

    br
    h3(class: 'udl udl--fw allcaps h4') { 'Opening times' }
    ul(class: 'opening_times reset') do
      times.each do |slot|
        li { slot }
      end
    end
  end

  def render_managees
    partner.managees.each do |place|
      hr

      h2(class: 'place__title') { link_to place.name, partner_path(place), class: 'udl udl--red' }
      div(class: 'g g--place-list') do
        div(class: 'gi gi__1-2') do
          raw safe(place.summary_html.to_s) if place.summary_html.present?
        end
        div(class: 'gi gi__1-2') do
          h2(class: 'udl udl--fw allcaps h4') { 'Address' }
          div(class: 'small') do
            Address(address: place.address)
          end
          h2(class: 'udl udl--fw allcaps h4') { 'Contact' }
          div(class: 'small') do
            ContactDetails(
              partner: partner,
              email: place.public_email,
              phone: place.public_phone,
              url: place.url
            )
          end
        end
      end
    end
  end

  def render_events_section
    turbo_frame_tag 'events-browser', data: { turbo_action: 'advance' } do
      render_events_paginator if paginator

      if events.any?
        EventList(
          events: events,
          period: period,
          primary_neighbourhood: site.primary_neighbourhood,
          show_neighbourhoods: site.show_neighbourhoods?,
          badge_zoom_level: site.badge_zoom_level&.to_s,
          site_tagline: site.tagline,
          context_partner: partner
        )
      else
        p { em { no_event_message || empty_period_message } }
      end
    end
  end

  def render_events_paginator
    path = "partners/#{partner.slug}/events"
    today = Time.zone.today
    filter_period = date_period || period
    div(class: 'paginator', id: 'paginator') do
      Timeline(
        pointer: current_day,
        period: period,
        date_period: date_period,
        sort: sort,
        repeating: repeating,
        path: path,
        show_upcoming: true
      )
      div(class: 'paginator__actions') do
        today_url = "/#{path}/#{today.year}/#{today.month}/#{today.day}?period=#{filter_period}&sort=#{sort}&repeating=#{repeating}#paginator"
        EventFilter(
          pointer: current_day,
          period: filter_period,
          sort: sort,
          repeating: repeating,
          today_url: today_url,
          today: current_day == today,
          show_monthly: show_monthly
        )
      end
    end
  end

  def empty_period_message
    case period
    when 'day' then 'No events this day.'
    when 'week' then 'No events this week.'
    when 'month' then 'No events this month.'
    else 'No upcoming events.'
    end
  end

  def render_meta_section
    Meta("/partners/#{partner.id}") do |component|
      component.with_link do
        link_to "Subscribe to #{partner}'s events with iCal", partner_url(partner, protocol: :webcal, format: :ics)
      end
    end
  end
end
