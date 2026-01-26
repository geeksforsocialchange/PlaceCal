# frozen_string_literal: true

class EventListComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    today = Time.zone.today
    events = {
      today => [mock_event('Coffee Morning'), mock_event('Art Class'), mock_event('Book Club')]
    }
    render(EventListComponent.new(
             events: events,
             pointer: today,
             period: 'day'
           ))
  end

  # @label Week View
  def week_view
    today = Time.zone.today
    tomorrow = today + 1.day
    events = {
      today => [mock_event('Weekly Yoga')],
      tomorrow => [mock_event('Garden Club')]
    }
    render(EventListComponent.new(
             events: events,
             pointer: today.beginning_of_week,
             period: 'week'
           ))
  end

  # @label With Breadcrumb Hidden
  def without_breadcrumb
    today = Time.zone.today
    events = {
      today => [mock_event('Community Meeting')]
    }
    render(EventListComponent.new(
             events: events,
             pointer: today,
             period: 'day',
             show_breadcrumb: false
           ))
  end

  # @label Empty State
  def empty
    render(EventListComponent.new(
             events: {},
             pointer: Time.zone.today,
             period: 'day',
             site_name: 'PlaceCal Manchester'
           ))
  end

  private

  def mock_event(title)
    address = OpenStruct.new(street_address: '123 High Street')
    partner = OpenStruct.new(name: 'Community Centre', slug: 'community-centre')

    OpenStruct.new(
      id: rand(1000),
      summary: title,
      description: 'Event description',
      dtstart: Time.zone.now + rand(1..8).hours,
      dtend: Time.zone.now + rand(9..12).hours,
      partner: [partner],
      partner_at_location: partner,
      address: address,
      neighbourhood: OpenStruct.new(name: 'Hulme', name_from_badge_zoom: ->(_) { 'Hulme' }),
      online_address: nil,
      rrule: nil
    )
  end
end
