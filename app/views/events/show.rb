# frozen_string_literal: true

class Views::Events::Show < Views::Base
  register_output_helper :event_link
  register_output_helper :online_link
  register_value_helper :html_to_plaintext

  prop :event, ::Event, reader: :private
  prop :site, _Nilable(::Site), reader: :private
  prop :map, _Nilable(Array), reader: :private
  prop :more_from_organiser, _Nilable(_Interface(:each)), reader: :private, default: nil

  def view_template
    content_for(:title) { event.og_title }
    content_for(:canonical) { event.permalink }
    # Past events have no search value and accumulate forever — noindex them
    # so they stop eating crawl budget and diluting the indexed site.
    content_for(:robots) { 'noindex, noarchive' } if event.past?
    content_for(:image) { event_og_image_url(event) }
    content_for(:image_alt) { t('og_image.alt.event', name: event.summary) }
    content_for(:description) { html_to_plaintext(event.description_html) }
    # Directory apex, matching the canonical tag — see partners/show.rb.
    content_for(:json_ld) { safe(event.to_json_ld(base_url: ::Site::DIRECTORY_URL).to_json) }

    if site.nil?
      render_directory_layout
    else
      Event(
        display_context: :page,
        event: event,
        primary_neighbourhood: site.primary_neighbourhood,
        site_tagline: site.tagline
      )
      render_event_details
      Map(points: map, site: site.slug, style: :multi)
      render_event_meta
    end
  end

  private

  # ── Directory layout (nil site) ──
  # Follows the design handoff for the directory event page: hero with
  # breadcrumb trail + chip row, then a two-column body — About / Where /
  # More-from-organiser on the left, Event information / Organised by /
  # Canonical URL cards on the right.

  def render_directory_layout
    Directory::PageHero(
      title: event.summary,
      breadcrumbs: hero_breadcrumbs
    ) do
      render_hero_chips
    end

    div(class: 'container-public py-6') do
      div(class: 'lg:grid lg:grid-cols-[1fr_var(--width-sidebar)] lg:gap-8') do
        div do
          render_about_section
          render_where_section if map || event.address
          render_more_from_organiser if Array(more_from_organiser).any?
        end
        aside(class: 'flex flex-col gap-4 max-lg:mt-8') do
          render_information_card
          render_organiser_contact_card if event.organiser
          render_share_card
        end
      end
    end
  end

  def hero_breadcrumbs
    crumbs = [{ label: ::Event.model_name.human(count: 2), path: events_path }]
    crumbs << { label: event.organiser.name, path: partner_path(event.organiser) } if event.organiser
    crumbs << { label: event.summary }
    crumbs
  end

  # ── Hero chips ──

  def render_hero_chips
    div(class: 'flex flex-wrap gap-2 mt-4 mb-2') do
      hero_chip(:event_date, event.dtstart.strftime('%a %-e %b'))
      render_hero_time
      hero_chip(:event_repeats, event.repeat_frequency) if event.repeat_frequency
      hero_chip(:event_online, t('directory.event_row.online')) if event.online_address.present?
    end
  end

  def hero_chip(icon_name, text)
    span(class: 'inline-flex items-center gap-1.5 rounded-full bg-background/15 px-3 py-1 text-sm') do
      raw(view_context.icon(icon_name, size: nil, css_class: 'w-3.5 h-3.5 shrink-0 opacity-80'))
      plain text
    end
  end

  def render_hero_time
    span(class: 'inline-flex items-center gap-1.5 rounded-full bg-background/15 px-3 py-1 text-sm') do
      raw(view_context.icon(:event_time, size: nil, css_class: 'w-3.5 h-3.5 shrink-0 opacity-80'))
      time(class: 'dt-start', datetime: event.dtstart.iso8601) { event.dtstart.strftime('%H:%M') }
      if event.dtend
        plain ' – '
        time(class: 'dt-end', datetime: event.dtend.iso8601) { event.dtend.strftime('%H:%M') }
      end
    end
  end

  # ── Left column ──

  def render_about_section
    div(class: 'pb-4') do
      # No heading, bigger lead paragraph — same treatment as the partner page
      # description (first-ele-lg enlarges the first <p>).
      div(class: 'e-content first-ele-lg max-w-(--width-prose-md)') { raw safe(event.description_html.to_s) } if event.description_html.present?
      div(class: 'mt-3') do
        event_link(event)
        online_link
      end
    end
  end

  def render_where_section
    div(class: 'py-4') do
      section_heading(t('directory.events.show.where'))
      div(class: 'grid grid-cols-[1fr_auto] gap-4 items-start') do
        # No style: override — a single point resolves to map--single, whose
        # compact height actually applies (map--multiple's 500px wins the
        # cascade over map--compact). Matches directory/partners/show.
        Map(points: map, site: site&.slug, compact: true) if map
        div do
          div(class: 'font-extra-bold') { event.partner_at_location.name } if event.partner_at_location
          Address(address: event.address, raw_location: event.raw_location_from_source)
          if event.neighbourhood
            div(class: 'text-tertiary text-sm mt-1') do
              plain t('directory.events.show.ward', name: event.neighbourhood.shortname)
            end
          end
        end
      end
    end
  end

  def render_more_from_organiser
    div(class: 'py-4') do
      section_heading(t('directory.events.show.more_from', name: event.organiser.name))
      Array(more_from_organiser).each do |other_event|
        Directory::EventRow(event: other_event, context_partner: event.organiser)
      end
    end
  end

  # Section heading matching the directory partner page (underlined, full-width).
  def section_heading(text)
    h2(class: 'udl udl--fw allcaps text-xl') { text }
  end

  # ── Right column cards ──
  # Same card idiom as Directory::PartnerSidebar: light rounded cards with a
  # sidebar_heading and simple icon + value rows at text-sm.

  def render_information_card
    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      sidebar_heading(t('directory.events.show.information'))
      div(class: 'flex flex-col gap-2') do
        info_row(:event_date) { event.dtstart.strftime('%a %-e %b %Y') }
        info_row(:event_time) { event.time }
        info_row(:event_repeats) { event.repeat_frequency } if event.repeat_frequency
        if event.partner_at_location
          info_row(:event_place) do
            link_to event.partner_at_location.name, partner_path(event.partner_at_location), class: info_link_classes
          end
        end
        info_row(:neighbourhood) { neighbourhood_line } if event.neighbourhood
        if event.online_address
          info_row(:event_online) do
            link_to strip_scheme(event.online_address.url), event.online_address.url,
                    class: info_link_classes, target: '_blank', rel: 'noopener'
          end
        end
      end
    end
  end

  # Titled with the organiser (same SidebarCard as the partner sidebar's
  # "Part of" card) so the contacts read as the organiser's, not the event's.
  def render_organiser_contact_card
    organiser = event.organiser
    card_args = {
      eyebrow: t('directory.events.show.organised_by'),
      title: organiser.name,
      title_href: partner_path(organiser)
    }
    # Skip the light body entirely when there's nothing to put in it, so a
    # contactless organiser gets a clean titled card, not an empty strip.
    if organiser.contactable?
      Directory::SidebarCard(**card_args) do
        render ContactDetails.new(partner: organiser, variant: :tailwind_rows)
      end
    else
      Directory::SidebarCard(**card_args)
    end
  end

  def render_share_card
    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      sidebar_heading(t('directory.sidebar.share_subscribe'))
      div do
        a(href: "https://placecal.org/events/#{event.id}",
          class: 'font-mono text-sm text-foreground break-all no-underline hover:underline hover:decoration-primary') do
          plain "placecal.org/events/#{event.id}"
        end
      end
      div(class: 'mt-3') do
        a(href: event_url(event, protocol: :webcal, format: :ics),
          class: 'inline-flex items-center gap-1.5 text-sm font-bold text-foreground no-underline hover:underline hover:decoration-primary') do
          raw(view_context.icon(:calendar, size: '3.5'))
          plain t('directory.sidebar.subscribe_ical')
        end
      end
    end
  end

  # ── Shared bits ──

  def info_row(icon_name, &)
    div(class: 'flex items-center gap-2.5 text-sm text-foreground') do
      raw(view_context.icon(icon_name, size: '4'))
      span(&)
    end
  end

  def info_link_classes
    'text-foreground underline decoration-primary decoration-2 underline-offset-2 hover:text-foreground/80'
  end

  def neighbourhood_line
    parts = [event.neighbourhood.shortname, event.neighbourhood.district&.shortname].compact
    parts.join(', ')
  end

  def strip_scheme(url)
    url.to_s.sub(%r{\Ahttps?://(www\.)?}, '').chomp('/')
  end

  # ── Local site layout ──

  def render_event_details
    div(class: 'container-narrowish mb-12 event__fullinfo e-content') do
      raw safe(event.description_html.to_s)
      event_link(event)

      br

      online_link

      div(class: 'g three-col') do
        render_contact_info
        render_event_address
        render_event_organiser
        render_event_venue if show_venue?
      end
    end
  end

  def render_contact_info
    div(class: 'gi gi__1-3') do
      if event.organiser
        h3(class: 'h4 udl') { 'Contact information' }
        div(class: 'small') do
          ContactDetails(partner: event.organiser)
        end
      end
    end
  end

  def render_event_address
    div(class: 'gi gi__1-3') do
      h3(class: 'h4 udl') { 'Event address' }
      div(class: 'small') do
        Address(address: event.address, raw_location: event.raw_location_from_source)
      end
    end
  end

  def render_event_organiser
    div(class: 'gi gi__1-3') do
      h3(class: 'h4 udl') { 'Event organiser' }
      div(class: 'small') do
        span { link_to event.organiser, event.organiser }
      end
    end
  end

  def show_venue?
    event.place.present? && event.place != event.organiser
  end

  def render_event_venue
    div(class: 'gi gi__1-3') do
      h3(class: 'h4 udl') { 'Venue' }
      div(class: 'small') do
        span { link_to event.place, event.place }
      end
    end
  end

  def render_event_meta
    Meta("/events/#{event.id}") do |component|
      component.with_link do
        contact = event.calendar&.contact_information
        if contact
          div(class: 'contact_information') do
            plain 'Problem with this listing? '
            mail_to contact[0],
                    'Let us know.',
                    subject: "I think there's a problem with PlaceCal event http://placecal.org#{event_path(event)}",
                    cc: 'support@placecal.org'
          end
        end
      end
    end
  end
end
