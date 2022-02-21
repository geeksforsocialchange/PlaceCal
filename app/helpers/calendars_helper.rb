# frozen_string_literal: true

module CalendarsHelper
  def options_for_organiser
    org_opts = policy_scope(Partner).order(:name).collect { |opt| [ opt.name, opt.id ] }

    #[{ name: '', id: ''}] + org_opts
    [[ '(No Partner)', '', { disabled: true }]] + org_opts
  end

  def options_for_location
    policy_scope(Partner).order(:name)
  end

  def summarize_dates(dates)
    if dates.length > 3
      sorted = dates.sort
      "#{dates.count} dates between #{sorted.first.strftime('%a, %b %e, %Y')} and #{sorted.last.strftime('%a, %b %e, %Y')}"
    else
      dates.map { |date| date.strftime('%b %e %Y (%a)') }.join(', ')
    end
  end

  def strategy_label val
    case val.second
    when 'event'
      '<strong>Event</strong>: ' \
      "Get the location of this event from the address field on the source event. " \
      "This is for area calendars, or organisations with no solid base.".html_safe
    when 'place'
      "<strong>Default location</strong>: " \
      "Every event is in one location (set below). The address field on the source calendar is ignored.".html_safe
    when 'room_number'
      "<strong>Room Number</strong>: " \
      "Every event is on one location (set below), and the address field is used " \
      "to store a room number.".html_safe
    when 'event_override'
      "<strong>Event Override</strong>: " \
      "Every event is in one location (set below), unless the address field " \
      "is set to another location".html_safe
    else
      val
    end
  end


  def display_time_since(date)
    if DateTime.current.to_date == date.to_date
      'Today'
    else
      "#{(Date.current - date).to_i} Days Ago"
    end
  end
end
