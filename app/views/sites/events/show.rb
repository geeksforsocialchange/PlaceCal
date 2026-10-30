# frozen_string_literal: true

class Views::Sites::Events::Show < Views::Base
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
      Sites::Event(
        display_context: :page,
        event:,
        site_tagline: site.tagline,
        back: [t('events.show.back'), events_path]
      )
      render_event_details
      UI::Stripe() if site.core_theme? && map.present?
      Shared::Map(points: map, style: :multi)
      render_site_more_from_organiser if Array(more_from_organiser).any?
      render_page_actions
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
      div(class: 'lg:grid lg:grid-cols-sidebar lg:gap-8') do
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
    UI::Pill(variant: :overlay) do
      raw(view_context.icon(icon_name, size: nil, css_class: 'w-3.5 h-3.5 shrink-0 opacity-80'))
      plain text
    end
  end

  def render_hero_time
    UI::Pill(variant: :overlay) do
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
      div(class: 'e-content first-p:text-xl first-p:leading-snug max-w-(--width-prose-md)') { raw safe(event.description_html.to_s) } if event.description_html.present?
      div(class: 'mt-3') do
        render_event_link
        render_online_link
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
        Shared::Map(points: map, compact: true) if map
        div do
          div(class: 'font-extra-bold') { event.partner_at_location.name } if event.partner_at_location
          Shared::Address(address: event.address, raw_location: event.raw_location_from_source)
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
    UI::RuledHeading(caps: true, rule: :full, size: :lg) { text }
  end

  # ── Right column cards ──
  # Same card idiom as Directory::PartnerSidebar: light rounded cards with a
  # sidebar_heading and simple icon + value rows at text-sm.

  def render_information_card
    UI::Card(variant: :panel, padding: :sm) do
      sidebar_heading(t('directory.events.show.information'))
      div(class: 'flex flex-col gap-2') do
        info_row(:event_date) { event.dtstart.strftime('%a %-e %b %Y') }
        info_row(:event_time) { event.time }
        info_row(:event_repeats) { event.repeat_frequency } if event.repeat_frequency
        if event.partner_at_location
          info_row(:event_place) do
            UI::Link(href: partner_path(event.partner_at_location)) { event.partner_at_location.name }
          end
        end
        info_row(:neighbourhood) { neighbourhood_line } if event.neighbourhood
        if event.online_address
          info_row(:event_online) do
            UI::Link(href: event.online_address.url, target: '_blank', rel: 'noopener') { strip_scheme(event.online_address.url) }
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
        render Components::Shared::ContactDetails.new(partner: organiser, variant: :tailwind_rows)
      end
    else
      Directory::SidebarCard(**card_args)
    end
  end

  def render_share_card
    UI::Card(variant: :panel, padding: :sm) do
      sidebar_heading(t('directory.sidebar.share_subscribe'))
      div do
        UI::Link(href: "https://placecal.org/events/#{event.id}", variant: :quiet, class: 'font-mono text-sm break-all') do
          plain "placecal.org/events/#{event.id}"
        end
      end
      div(class: 'mt-3') do
        UI::Link(href: event_url(event, protocol: :webcal, format: :ics), variant: :action, class: 'text-sm') do
          raw(view_context.icon(:calendar, size: '3.5'))
          plain t('directory.sidebar.subscribe_ical')
        end
      end
    end
  end

  # ── Shared bits ──

  def render_event_link
    return if event.publisher_url.blank?

    event_button(event.publisher_url, t('events.show.visit_webpage'))
  end

  # A stream gets a direct join link; any other online address only stands in for a missing webpage link.
  def render_online_link
    online_address = event.online_address
    return if online_address.nil?

    if online_address.link_type == :stream
      event_button(online_address.url, t('events.show.join_meeting'))
    elsif event.publisher_url.blank?
      event_button(online_address.url, t('events.show.visit_webpage'))
    end
  end

  def event_button(href, label)
    UI::Button(variant: :outline, href:, class: 'btn') { label }
  end

  def info_row(icon_name, &)
    div(class: 'flex items-center gap-2.5 text-sm text-foreground') do
      raw(view_context.icon(icon_name, size: '4'))
      span(&)
    end
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
      div(class: 'event__links flex flex-col items-start gap-2 mt-10 empty:hidden') do
        render_event_link
        render_online_link
      end

      div(class: 'event__columns grid gap-4 items-start mt-5.5 lg:grid-cols-3') do
        render_contact_info
        render_event_address
        render_event_organiser
        render_event_venue if show_venue?
      end
    end
  end

  # h2, not h3: these are the first headings under the page h1, and Tailwind's
  # preflight flattens every heading to the inherited size with no margin, so
  # the promotion changes the outline and not the look.
  def render_contact_info
    div(class: 'event__column') do
      if event.organiser
        UI::RuledHeading(size: :lg, spacing: :section) { t('events.show.contact_heading') }
        div(class: 'event__column-body text-sm leading-normal') do
          p(class: 'contact_details__partner') { link_to(event.organiser.name, partner_path(event.organiser)) }
          Shared::ContactDetails(partner: event.organiser, social_labels: site&.core_theme? ? :handle : :network)
        end
      end
    end
  end

  def render_event_address
    div(class: 'event__column') do
      UI::RuledHeading(size: :lg, spacing: :section) { t('events.show.address_heading') }
      div(class: 'event__column-body text-sm leading-normal') do
        Shared::Address(address: event.address, raw_location: event.raw_location_from_source)
      end
    end
  end

  def render_event_organiser
    div(class: 'event__column') do
      UI::RuledHeading(size: :lg, spacing: :section) { t('events.show.organiser_heading') }
      div(class: 'event__column-body text-sm leading-normal') do
        span { link_to event.organiser, event.organiser }
      end
    end
  end

  def show_venue?
    event.place.present? && !event.place.hidden && event.place != event.organiser
  end

  def render_event_venue
    div(class: 'event__column') do
      UI::RuledHeading(size: :lg, spacing: :section) { t('events.show.venue_heading') }
      div(class: 'event__column-body text-sm leading-normal') do
        span { link_to event.place, event.place }
      end
    end
  end

  def render_site_more_from_organiser
    section(class: 'container-narrowish event__more') do
      UI::RuledHeading { t('events.show.more_from', name: event.organiser.name) }
      ul(class: 'events reset') do
        Array(more_from_organiser).each do |other_event|
          li(class: 'block w-full') { Sites::Event(event: other_event, context_partner: event.organiser) }
        end
      end
    end
  end

  # Page actions row (Components::Sites::PageActions, #3368): organiser's other
  # events (when there is an organiser), add to calendar, back to the index.
  def render_page_actions
    links = []
    links << [t('events.show.organiser_events', name: event.organiser.name), partner_path(event.organiser)] if event.organiser
    links << [t('events.show.add_to_calendar'), event_url(event, protocol: :webcal, format: :ics)]
    links << [t('events.show.go_back'), events_path]
    Sites::PageActions(links:)
  end

  def render_event_meta
    Sites::Meta("/events/#{event.id}") do |component|
      component.with_link do
        contact = event.calendar&.contact_information
        if contact
          div do
            plain t('events.show.problem_prompt')
            mail_to contact[0],
                    t('events.show.problem_link'),
                    subject: t('events.show.problem_subject',
                               url: "http://placecal.org#{event_path(event)}"),
                    cc: 'support@placecal.org',
                    class: Sites::Meta::LINK
          end
        end
      end
    end
  end
end
