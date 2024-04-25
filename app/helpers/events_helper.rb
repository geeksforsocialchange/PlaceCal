# frozen_string_literal: true

module EventsHelper
  def options_for_events
    Event.all.collect { |e| [e.summary, e.id] }
  end

  def event_link(event)
    return if @event.publisher_url.blank?

    link_to('Visit the webpage for this event',
            event.publisher_url,
            class: 'btn btn-primary').html_safe
  end

  def online_link
    online_address = @event&.online_address

    return if online_address.nil?

    # If the online address has a web stream, we want a direct link to join that
    # Otherwise we should probably only show the online url if publisher_url is missing,
    # to avoid having two links that head to the same place
    if online_address.link_type == :stream
      link_to('Join this meeting',
              online_address.url,
              class: 'btn btn-primary').html_safe
    elsif @event.publisher_url.blank?
      link_to('Visit the webpage for this event',
              online_address.url,
              class: 'btn btn-primary').html_safe
    end
  end

  def html_to_plaintext(input)
    Nokogiri::HTML.fragment(input).text
  end
end
