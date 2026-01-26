# frozen_string_literal: true

class EventComponentPreview < ViewComponent::Preview
  # @label List Context
  def list_context
    event = mock_event
    render(EventComponent.new(context: :list, event: event))
  end

  # @label Page Context (Full Detail)
  def page_context
    event = mock_event
    render(EventComponent.new(context: :page, event: event))
  end

  # @label With Neighbourhood Badge
  def with_neighbourhood
    event = mock_event
    render(EventComponent.new(
             context: :list,
             event: event,
             show_neighbourhoods: true,
             badge_zoom_level: 10
           ))
  end

  # @label Online Event
  def online_event
    event = mock_event(online: true)
    render(EventComponent.new(context: :list, event: event))
  end

  private

  def mock_event(online: false)
    address = OpenStruct.new(
      street_address: '123 High Street',
      neighbourhood: OpenStruct.new(
        name: 'Hulme',
        name_from_badge_zoom: ->(_level) { 'Hulme' }
      )
    )

    partner = OpenStruct.new(
      name: 'Community Centre',
      slug: 'community-centre'
    )

    neighbourhood = OpenStruct.new(
      name: 'Hulme',
      name_from_badge_zoom: ->(_level) { 'Hulme' }
    )

    OpenStruct.new(
      id: 1,
      summary: 'Weekly Coffee Morning',
      description: 'Join us for tea, coffee, and a chat with neighbours.',
      dtstart: 1.day.from_now,
      dtend: 1.day.from_now + 2.hours,
      partner: [partner],
      partner_at_location: partner,
      address: address,
      neighbourhood: neighbourhood,
      online_address: online ? 'https://zoom.us/j/123456789' : nil,
      rrule: nil
    )
  end
end
