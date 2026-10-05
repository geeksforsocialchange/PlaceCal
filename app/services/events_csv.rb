# frozen_string_literal: true

require 'csv'

# Builds a CSV of events for download, one row per event.
#
# The column set is designed to feed Canva's Bulk Create feature
# (https://www.canva.com/help/bulk-create/), which generates one design per
# row from a poster template. Bulk Create treats URLs in cells as plain
# text, so every column is text — image URLs would not flow into image
# frames. See doc/canva-posters.md.
class EventsCsv
  HEADERS = %i[title date time location organiser url description].freeze

  # @param events [Enumerable<Event>]
  # @param site_url [String] base URL used to build each event's page link
  def initialize(events, site_url:)
    @events = events
    @site_url = site_url
  end

  # @return [String] UTF-8 CSV with a header row
  def call
    CSV.generate do |csv|
      csv << HEADERS.map { |header| I18n.t("events.csv_export.headers.#{header}") }
      @events.each { |event| csv << row(event) }
    end
  end

  private

  def row(event)
    [
      event.summary,
      event.date_year.strip,
      event.time,
      event.location,
      event.organiser&.name,
      "#{@site_url}/events/#{event.id}",
      plain_description(event)
    ]
  end

  # Descriptions imported from iCal sources keep RFC 5545 escape sequences
  # (same set handled by ApplicationController#unescape_ical_text); a poster
  # blurb wants none of them, nor any line breaks.
  def plain_description(event)
    event.description.to_s
         .gsub('\\n', ' ')
         .gsub('\\,', ',')
         .gsub('\\;', ';')
         .gsub("\\'", "'")
         .gsub('\\"', '"')
         .gsub('\\\\', '\\')
         .squish
  end
end
