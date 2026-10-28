# frozen_string_literal: true

module EventsHelper
  def options_for_events
    Event.all.collect { |e| [e.summary, e.id] }
  end

  def html_to_plaintext(input)
    Nokogiri::HTML.fragment(input).text
  end

  def next_url(date)
    opts = {
      year: date.year,
      month: date.month,
      day: date.day,
      anchor: 'paginator',
      period: @period,
      sort: @sort,
      repeating: @repeating
    }.compact_blank!

    events_by_date_path(opts)
  end
end
