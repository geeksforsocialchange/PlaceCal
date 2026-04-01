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

  def view_template
    content_for(:title) { partner.name }
    if partner.image.present?
      content_for(:image) { partner.image }
    else
      content_for(:image) { site.og_image }
    end
    content_for(:description) { partner.summary } if partner.summary
    content_for(:json_ld) { safe(partner.to_json_ld(base_url: request.base_url).to_json) }

    div do
      Hero(partner.name, site.tagline)

      div(class: 'c c--lg-space-after') do
        Breadcrumb(
          trail: [['Partners', partners_path], [partner.name, partner_path(partner)]],
          site_name: site.name
        )

        hr
        render_partner_details
        render_managees
        hr
        render_events_section
      end
    end

    render_meta_section
  end

  private

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
          h3(class: 'udl udl--fw allcaps h4') { 'Address' }
          div(class: 'small') do
            Address(address: place.address)
          end
          h3(class: 'udl udl--fw allcaps h4') { 'Contact' }
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
    # Use date_period for filter/URL context, period for active state
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
