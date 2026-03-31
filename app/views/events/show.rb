# frozen_string_literal: true

class Views::Events::Show < Views::Base
  register_output_helper :event_link
  register_output_helper :online_link
  register_value_helper :html_to_plaintext

  prop :event, ::Event, reader: :private
  prop :site, Site, reader: :private
  prop :map, _Nilable(Array), reader: :private

  def view_template
    content_for(:title) { event.og_title }
    content_for(:image) { site.og_image }
    content_for(:description) { html_to_plaintext(event.description_html) }
    content_for(:json_ld) { safe(event.to_json_ld(base_url: request.base_url).to_json) }

    div(class: 'h-event') do
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

  def render_event_details
    div(class: 'c c--narrowish c--space-after event__fullinfo e-content') do
      raw safe(event.description_html.to_s)
      event_link(event)

      br

      online_link

      div(class: 'g three-col') do
        render_contact_info
        render_event_address
        render_event_organiser
      end
    end
  end

  def render_contact_info
    div(class: 'gi gi__1-3') do
      if event.partner
        h3(class: 'h4 udl') { 'Contact information' }
        div(class: 'small') do
          ContactDetails(partner: event.partner)
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
        span { link_to event.partner, event.partner }
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
