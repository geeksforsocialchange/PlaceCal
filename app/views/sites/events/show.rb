# frozen_string_literal: true

class Views::Sites::Events::Show < Views::Base
  include Components::Shared::LongRunningDates

  register_value_helper :html_to_plaintext

  MIN_DESCRIPTION_LENGTH = 100
  SECTION_BODY = 'text-sm leading-normal'
  # Core themes sit the details close under their headings, with the venue's name and the address as one block
  CORE_SECTION_BODY = 'details-body'

  theme_scope :event_details,
              parts: {
                root: 'Everything under the event\'s details row on its page.',
                description: 'The event\'s description, as its organiser wrote it (paragraphs, lists, headings).',
                links: 'The buttons under the description: the event\'s webpage and a join link for streams. Only when the event has them.',
                columns: 'The description and links beside the event\'s image, like the partner page. Only when the event has an image.',
                aside: 'The column beside the description, holding the event\'s image. Only when the event has an image.',
                image: 'The box holding the event\'s image, the same as a partner page\'s. Only when the event has one.',
                info: 'The group of headed sections below the description: on core themes online, location and contact, and on others contact, address, organiser and venue.',
                contact: 'The organiser\'s contact section. Its heading only when the event has an organiser.',
                contact_name: 'The organiser\'s name, linked, heading the contact details. Not on core themes.',
                address: 'The event\'s address section.',
                online: 'On core themes, the Online section: which service the event is on and how to join.',
                online_service: 'The video icon and the service the event is on.',
                online_note: 'For a link to a page rather than the meeting itself, that the joining details are on that page.',
                organiser: 'The organiser section, linking to their page. Not on core themes, which name the organiser above the address.',
                organiser_name: 'On core themes, "By" and the organiser\'s name, linked, at the top of the address section.',
                venue: 'The venue section, when the venue is a different partner from the organiser. On core themes, the venue\'s name above the address instead.',
                section_body: 'The text under each section\'s heading.',
                more: 'The "More from" list of the organiser\'s other events. Only when the organiser has other upcoming events.'
              },
              tokens: %i[--text-sm --leading-normal --color-foreground --color-primary --color-rules --radius-card]

  prop :event, ::Event, reader: :private
  prop :site, _Nilable(::Site), reader: :private
  prop :map, _Nilable(Array), reader: :private
  prop :more_from_organiser, _Nilable(_Interface(:each)), reader: :private, default: nil

  def view_template
    content_for(:title) { event.og_title }
    content_for(:canonical) { permalink }
    # Past events have no search value and accumulate forever — noindex them
    # so they stop eating crawl budget and diluting the indexed site.
    content_for(:robots) { 'noindex' } if event.past?
    content_for(:image) { event_og_image_url(event) }
    content_for(:image_alt) { t('og_image.alt.event', name: event.summary, site: site&.name || 'PlaceCal') }
    content_for(:description) { meta_description }
    content_for(:json_ld) { safe(event.to_json_ld(base_url: ::Site.permalink_base_url_for(site), organiser_base_url:).to_json) }

    if site.nil?
      render_directory_layout
    else
      Sites::Event(
        display_context: :page,
        event:,
        site_tagline: site.tagline,
        organiser_byline: !site.core_theme?,
        online_on: site.core_theme?
      )
      render_event_details
      # Core themes show the map boxed beside the address instead
      Shared::Map(points: map, style: :multi) unless site.core_theme?
      render_site_more_from_organiser if Array(more_from_organiser).any?
      # Core themes put the actions in the meta band, as partner pages do
      render_page_actions unless site.core_theme?
      render_event_meta
    end
  end

  private

  def permalink
    event.permalink(base_url: ::Site.permalink_base_url_for(site))
  end

  # An organiser from outside the site has its page on the directory, even if the event shows here.
  def organiser_base_url
    on_site = event.organiser && site&.served_domain? && PartnersQuery.new(site:).include?(event.organiser)
    on_site ? site.canonical_url : ::Site::DIRECTORY_URL
  end

  # A very short description says less than the date and place, so those lead.
  def meta_description
    description = html_to_plaintext(event.description_html).to_s.squish
    return description if description.length >= MIN_DESCRIPTION_LENGTH

    [fallback_description, description].compact_blank.join(' ')
  end

  def fallback_description
    organiser = event.organiser&.name
    place = (event.partner_at_location || event.address)&.then { |at| at.try(:name) || at.try(:street_address) }
    place = nil if place == organiser
    key = ['meta_description', ('organiser' if organiser), ('place' if place)].compact.join('_')
    t("events.show.#{key}", summary: event.summary, date: event.dtstart.strftime(t('events.show.meta_date_format')), organiser:, place:)
  end

  # ── Directory layout (nil site) ──
  # Follows the design handoff for the directory event page: hero with
  # breadcrumb trail + chip row, then a two-column body — About / Where /
  # More-from-organiser on the left, Event information / Organised by /
  # Canonical URL cards on the right.

  def render_directory_layout
    Directory::PageHero(
      title: event.summary,
      struck: event.called_off?,
      breadcrumbs: hero_breadcrumbs
    ) do
      render_hero_chips
    end

    div(class: 'container-public py-6') do
      p(class: 'mb-6 text-lg font-bold') { t("events.show.status_notice.#{event.status}") } if event.called_off?
      div(class: 'lg:grid lg:grid-cols-sidebar lg:gap-8') do
        div do
          render_about_section
          render_where_section if map || event.address
          render_more_from_organiser if Array(more_from_organiser).any?
        end
        aside(class: 'flex flex-col gap-4 max-lg:mt-8') do
          Shared::SidebarImage(src: event.image.url, webp_srcset: event_image_webp_srcset, alt: event.summary, layout: :directory) if event.image.present?
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
      if long_running?(event)
        hero_chip(:event_date, date_range_text(event), struck: event.called_off?)
      else
        hero_chip(:event_date, event.dtstart.strftime('%a %-e %b'), struck: event.called_off?)
        render_hero_time
      end
      hero_chip(:event_repeats, event.repeat_frequency) if event.repeat_frequency
      hero_chip(:event_online, event.online_address.service_name || t('directory.event_row.online')) if event.online_address.present?
    end
  end

  def hero_chip(icon_name, text, struck: false)
    UI::Pill(variant: :overlay) do
      raw(view_context.icon(icon_name, size: nil, css_class: 'w-3.5 h-3.5 shrink-0 opacity-80'))
      span(class: ('line-through' if struck)) { text }
    end
  end

  def render_hero_time
    UI::Pill(variant: :overlay) do
      raw(view_context.icon(:event_time, size: nil, css_class: 'w-3.5 h-3.5 shrink-0 opacity-80'))
      span(class: ('line-through' if event.called_off?)) do
        time(class: 'dt-start', datetime: event.dtstart.iso8601) { event.dtstart.strftime('%H:%M') }
        if event.dtend
          plain ' – '
          time(class: 'dt-end', datetime: event.dtend.iso8601) { event.dtend.strftime('%H:%M') }
        end
      end
    end
  end

  # ── Left column ──

  def render_about_section
    div(class: 'pb-4') do
      if event.description_html.present?
        div(class: 'e-content markdown-content first-p:text-xl first-p:leading-snug max-w-(--width-prose-md)') do
          raw safe(OrganiserHtml.call(event.description_html, under: 1))
        end
      end
      div(class: 'mt-3') do
        render_event_link
        render_online_link
      end
    end
  end

  def render_where_section
    div(class: 'py-4') do
      section_heading(t('directory.events.show.where'))
      # Address first so phones show it above the map; wider screens put the map on the left
      div(class: 'grid gap-4 items-start md:grid-cols-main-auto') do
        div(class: 'md:order-last') do
          div(class: 'font-extra-bold') { event.partner_at_location.name } if event.partner_at_location
          Shared::Address(address: event.address, raw_location: event.raw_location_from_source)
        end
        Shared::Map(points: map, compact: true) if map
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
      UI::Stack(gap: :sm) do
        if long_running?(event)
          info_row(:event_date, struck: event.called_off?) { date_range_text(event) }
        else
          info_row(:event_date, struck: event.called_off?) { event.dtstart.strftime('%a %-e %b %Y') }
          info_row(:event_time, struck: event.called_off?) { event.time }
        end
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
        render Components::Shared::ContactDetails.new(partner: organiser, variant: :rows)
      end
    else
      Directory::SidebarCard(**card_args)
    end
  end

  def render_share_card
    UI::Card(variant: :panel, padding: :sm) do
      sidebar_heading(t('directory.sidebar.share_subscribe'))
      div do
        UI::Link(href: "https://placecal.org/events/#{event.id}", variant: :quiet, font: :code) do
          plain "placecal.org/events/#{event.id}"
        end
      end
      div(class: 'mt-3') do
        UI::Link(href: event_url(event, protocol: :webcal, format: :ics), variant: :action, size: :sm) do
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

  def render_online_link
    return if event.online_address.nil?

    Shared::OnlineEventButton(online_address: event.online_address, has_webpage: event.publisher_url.present?)
  end

  def event_button(href, label)
    UI::Button(variant: :outline, href:) { label }
  end

  def info_row(icon_name, struck: false, &)
    div(class: 'flex items-center gap-2.5 text-sm text-foreground') do
      raw(view_context.icon(icon_name, size: '4'))
      span(class: ('line-through' if struck), &)
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
    div(**part(:root, class: "#{core_theme? ? 'container-public' : 'container-narrowish'} mb-12 e-content")) do
      core_theme? ? render_core_details : render_extension_details
    end
  end

  # The partner page's columns: the text, address and contact on the left, the image and map on the right
  def render_core_details
    div(**part(:columns, class: ('grid grid-areas-partner-details' if aside?))) do
      div(class: ('grid-area-main' if aside?)) do
        render_description_and_links
        div(**part(:info)) do
          render_online_section if event.online_address
          render_event_address if physical_location?
          render_contact_info if event.organiser&.contactable?
        end
      end
      if aside?
        aside(**part(:aside, class: 'grid-area-right max-lg:mt-8')) do
          UI::Stack(gap: :lg) do
            Shared::SidebarImage(src: event.image.url, webp_srcset: event_image_webp_srcset, alt: event.summary, **part(:image)) if event.image.present?
            Shared::Map(points: map, compact: true) if map.present?
          end
        end
      end
    end
  end

  def event_image_webp_srcset
    event.image.webp_srcset(standard: '1x', retina: '2x')
  end

  def aside?
    event.image.present? || map.present?
  end

  def render_extension_details
    if event.image.present?
      div(**part(:columns, class: 'grid grid-areas-partner-details')) do
        div(class: 'grid-area-main') { render_description_and_links }
        aside(**part(:aside, class: 'grid-area-right max-lg:mt-8')) { Shared::SidebarImage(src: event.image.url, webp_srcset: event_image_webp_srcset, alt: event.summary, **part(:image)) }
      end
    else
      render_description_and_links
    end
    render_info_sections
  end

  def render_info_sections
    div(**part(:info, class: 'grid gap-4 items-start mt-5.5 lg:grid-cols-3')) do
      render_contact_info
      render_event_address
      render_event_organiser if event.organiser
      render_event_venue if show_venue?
    end
  end

  def render_description_and_links
    div(**part(:description, class: 'markdown-content')) { raw safe(OrganiserHtml.call(event.description_html, under: 1)) }
    div(**part(:links, class: 'flex flex-col items-start gap-2 mt-10 empty:hidden')) do
      render_event_link
      render_online_link unless core_theme?
    end
  end

  # h2, not h3: these are the first headings under the page h1, and Tailwind's
  # preflight flattens every heading to the inherited size with no margin, so
  # the promotion changes the outline and not the look.
  def render_contact_info
    div(**part(:contact)) do
      if event.organiser
        details_heading { t(core_theme? ? 'partners.show.contact_heading' : 'events.show.contact_heading') }
        div(**part(:section_body, class: section_body)) do
          p(**part(:contact_name)) { link_to(event.organiser.name, partner_path(event.organiser)) } unless core_theme?
          Shared::ContactDetails(partner: event.organiser, social_labels: core_theme? ? :handle : :network)
        end
      end
    end
  end

  def render_online_section
    online_address = event.online_address
    div(**part(:online)) do
      details_heading { t('events.show.online_heading') }
      div(**part(:section_body, class: section_body)) do
        p(**part(:online_service, class: 'flex items-center gap-2')) do
          raw(view_context.icon(:video, size: '5'))
          plain(online_address.service_name ? t('events.show.online_on', service: online_address.service_name) : t('events.show.online_event'))
        end
        p(**part(:online_note)) { t('events.show.online_details_on_webpage') } unless online_address.link_type.direct?
        Shared::OnlineEventButton(online_address:, has_webpage: event.publisher_url.present?, variant: :primary)
      end
    end
  end

  # Feeds often give a meeting link as the location, which is not somewhere to go
  def physical_location?
    raw_location = event.raw_location_from_source.to_s.strip
    event.online_address.nil? || event.address.present? ||
      (raw_location.present? && !raw_location.match?(CalendarImporter::LocationResolver::ONLINE_LINK))
  end

  def render_event_address
    div(**part(:address)) do
      details_heading { t('events.show.address_heading') }
      div(**part(:section_body, class: section_body)) do
        if core_theme?
          p(**part(:organiser_name)) { raw safe(t('events.show.by_organiser_html', name: view_context.link_to(event.organiser.name, partner_path(event.organiser)))) } if event.organiser
          p(**part(:venue)) { link_to(venue.name, venue) } if venue && venue != event.organiser
        end
        Shared::Address(address: event.address, raw_location: event.raw_location_from_source)
      end
    end
  end

  def render_event_organiser
    div(**part(:organiser)) do
      details_heading { t('events.show.organiser_heading') }
      div(**part(:section_body, class: section_body)) do
        span { link_to event.organiser, event.organiser }
      end
    end
  end

  def show_venue?
    event.place.present? && !event.place.hidden && event.place != event.organiser
  end

  def render_event_venue
    div(**part(:venue)) do
      details_heading { t('events.show.venue_heading') }
      div(**part(:section_body, class: section_body)) do
        span { link_to event.place, event.place }
      end
    end
  end

  # The same partner the details row names as the event's location
  def venue
    event.partner_at_location
  end

  # Extension themes such as Trans Dimension keep the byline, the contact name and the Venue section, which their designs are built around
  def core_theme?
    site&.core_theme?
  end

  # On core themes, the partner page's section headings
  def details_heading(&)
    return UI::RuledHeading(caps: true, rule: :full, size: :lg, spacing: :section, &) if core_theme?

    UI::RuledHeading(size: :lg, spacing: :section, &)
  end

  def section_body
    core_theme? ? CORE_SECTION_BODY : SECTION_BODY
  end

  def render_site_more_from_organiser
    section(**part(:more, class: "#{core_theme? ? 'container-public' : 'container-narrowish'} mb-8")) do
      UI::RuledHeading(caps: true, rule: :none, size: :lg, spacing: :section) { t('events.show.more_from', name: event.organiser.name) }
      Sites::EventRows(events: Array(more_from_organiser), context_partner: event.organiser,
                       show_neighbourhoods: site.show_neighbourhoods?, badge_zoom_level: site.badge_zoom_level&.to_s)
      div(class: 'flex justify-center mt-6') do
        event_button(partner_path(event.organiser), t('events.show.all_organiser_events', name: event.organiser.name))
      end
    end
  end

  # Page actions row (Components::Sites::PageActions, #3368): organiser's other
  # events (when there is an organiser), add to calendar, back to the index.
  def render_page_actions
    Sites::PageActions(links: page_action_links)
  end

  def page_action_links
    links = []
    links << [t('events.show.organiser_events', name: event.organiser.name), partner_path(event.organiser)] if event.organiser
    links << [t('events.show.add_to_calendar'), event_url(event, protocol: :webcal, format: :ics)]
    links << [t('events.show.go_back'), events_path]
  end

  # The band's links on core themes: adding to a calendar, reporting a problem and the permalink
  def band_links
    links = [[t('events.show.add_to_calendar'), event_url(event, protocol: :webcal, format: :ics)]]
    contact = event.calendar&.contact_information
    if contact
      subject = t('events.show.problem_subject', url: "http://placecal.org#{event_path(event)}")
      links << [t('events.show.report_problem'), "mailto:#{contact[0]}?subject=#{ERB::Util.url_encode(subject)}&cc=support%40placecal.org"]
    end
    links << [t('components.meta.permalink'), permalink]
  end

  def render_event_meta
    return Sites::Meta() { |meta| meta.with_link { Sites::PageActions(links: band_links, in_meta_band: true) } } if site.core_theme?

    Sites::Meta(permalink) do |component|
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
