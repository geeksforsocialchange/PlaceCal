# frozen_string_literal: true

class Views::Sites::Events::Show < Views::Base
  register_output_helper :event_link
  register_output_helper :online_link
  register_value_helper :html_to_plaintext

  prop :event, ::Event, reader: :private
  prop :site, _Nilable(::Site), reader: :private
  prop :map, _Nilable(Array), reader: :private
  prop :containing_sites, _Nilable(_Interface(:each)), reader: :private, default: nil

  def view_template
    content_for(:title) { event.og_title }
    content_for(:image) { event_og_image_url(event) }
    content_for(:image_alt) { t('og_image.alt.event', name: event.summary) }
    content_for(:description) { html_to_plaintext(event.description_html) }
    content_for(:json_ld) { safe(event.to_json_ld(base_url: request.base_url).to_json) }

    if site.nil?
      render_directory_layout
    else
      Sites::Event(
        display_context: :page,
        event: event,
        primary_neighbourhood: site.primary_neighbourhood,
        site_tagline: site.tagline
      )
      render_event_details
      Shared::Map(points: map, site: site.slug, style: :multi)
      render_event_meta
    end
  end

  private

  # ── Directory layout (nil site) ──

  def render_directory_layout
    Directory::PageHero(
      title: event.summary,
      kicker: 'Event',
      breadcrumb_label: 'Events'
    )

    div(class: 'container-public py-6') do
      div(class: 'lg:grid lg:grid-cols-[1fr_340px] lg:gap-8') do
        div do
          render_directory_body
          render_directory_details
          render_directory_location
        end
        render_directory_sidebar
      end
    end
  end

  def render_directory_body
    return if event.description_html.blank?

    div(class: 'mb-6') do
      raw safe(event.description_html.to_s)
      event_link(event)
      online_link
    end
  end

  def render_directory_details
    div(class: 'grid md:grid-cols-3 gap-6 py-4') do
      if event.organiser
        div do
          h2(class: 'allcaps-label text-tertiary mb-2') { 'Contact information' }
          Shared::ContactDetails(partner: event.organiser)
        end
      end
      div do
        h2(class: 'allcaps-label text-tertiary mb-2') { 'Event address' }
        Shared::Address(address: event.address, raw_location: event.raw_location_from_source)
      end
      div do
        h2(class: 'allcaps-label text-tertiary mb-2') { 'Event organiser' }
        span { link_to event.organiser, event.organiser }
      end
      if show_venue?
        div do
          h2(class: 'allcaps-label text-tertiary mb-2') { 'Venue' }
          span { link_to event.place, event.place }
        end
      end
    end
  end

  def render_directory_location
    return unless map

    div(class: 'py-4') do
      Shared::Map(points: map, site: site&.slug, style: :multi)
    end
  end

  def render_directory_sidebar
    div(class: 'flex flex-col gap-6') do
      render_sidebar_partnerships if containing_sites&.any?
      render_sidebar_organiser if event.organiser
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
          plain 'This event appears on these local PlaceCal sites:'
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

  def render_sidebar_organiser
    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      h2(class: 'allcaps-label text-tertiary mb-2') { 'Organised by' }
      a(href: partner_path(event.organiser),
        class: 'font-extra-bold text-sm text-foreground no-underline hover:underline hover:decoration-primary') do
        plain event.organiser.name
      end
    end
  end

  def render_sidebar_share
    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      div(class: 'allcaps-label text-tertiary mb-3') { 'Share' }
      a(href: "https://placecal.org/events/#{event.id}",
        class: 'font-mono text-sm text-foreground break-all no-underline hover:underline hover:decoration-primary') do
        plain "placecal.org/events/#{event.id}"
      end
    end
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
          Shared::ContactDetails(partner: event.organiser)
        end
      end
    end
  end

  def render_event_address
    div(class: 'gi gi__1-3') do
      h3(class: 'h4 udl') { 'Event address' }
      div(class: 'small') do
        Shared::Address(address: event.address, raw_location: event.raw_location_from_source)
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
    Sites::Meta("/events/#{event.id}") do |component|
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
