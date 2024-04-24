# frozen_string_literal: true

module CalendarsHelper
  def options_for_organiser
    org_opts = policy_scope(Partner)
               .order(:name)
               .collect { |opt| [opt.name, opt.id] }

    # [{ name: '', id: ''}] + org_opts
    [['(No Partner)', '', { disabled: true }]] + org_opts
  end

  def options_for_location
    policy_scope(Partner)
      .with_address
      .order(:name)
  end

  def options_for_importer
    CalendarImporter::CalendarImporter::PARSERS
      .dup
      .keep_if { |parser| parser::PUBLIC }
      .map { |parser| [parser::NAME, parser::KEY] }
      .prepend(['(Auto detect)', 'auto'])
  end

  def summarize_dates(dates)
    if dates.length > 3
      sorted = dates.sort
      "#{dates.count} dates between #{sorted.first.strftime('%a, %b %e, %Y')} and #{sorted.last.strftime('%a, %b %e, %Y')}"
    else
      dates.map { |date| date.strftime('%b %e %Y (%a)') }.join(', ')
    end
  end

  def display_time_since(date)
    if DateTime.current.to_date == date.to_date
      'Today'
    else
      "#{(Date.current - date).to_i} Days Ago"
    end
  end

  def strategy_label(val)
    case val.second
    when 'event'
      '<strong>Event</strong>: ' \
      'Use the address from each event. '\
      'If an address is invalid or it doesn\'t have one, the event will import with no location.'.html_safe
    when 'place'
      '<strong>Default location</strong>: ' \
      'Always use the calendar\'s default location.'.html_safe
    when 'room_number'
      '<strong>Room number</strong>: ' \
      'Get a room number from the event\'s address, '\
      'and overwrite the rest of the address with the calendar\'s default location.'.html_safe
    when 'event_override'
      '<strong>Event where possible</strong>: ' \
      'Use the address from each event. '\
      'If the address is invalid or it doesn\'t have one, use the calendar\'s default location.'.html_safe
    when 'no_location'
      '<strong>No location</strong>: ' \
      'Discard any address information.'.html_safe
    when 'online_only'
      '<strong>Online only</strong>: ' \
      'Discard any address information but retain web links.'.html_safe
    else
      val
    end
  end

  def calendar_import_sources
    parsers = CalendarImporter::CalendarImporter::PARSERS
              .dup
              .keep_if { |parser| parser::PUBLIC }
              .sort { |a, b| a::NAME <=> b::NAME }

    parsers.each do |parser|
      yield parser::NAME, parser::DOMAINS
    end
  end

  def calendar_last_imported(calendar)
    if calendar&.last_import_at
      "Last imported #{time_ago_in_words(calendar.last_import_at)} ago"
    else
      'Never imported'
    end
  end
end
