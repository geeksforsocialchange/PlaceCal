# frozen_string_literal: true

class Views::Events::IndexText < Views::TextBase
  prop :events, Hash, reader: :private

  def text_content
    return '  No events with this selection.' unless events.any?

    lines = []
    events.each do |day, day_events|
      day_label = day.strftime('%A %e %B')
      padding = '#' * (day_label.length + 4)
      lines << padding
      lines << "# #{day_label} #"
      lines << padding

      day_events.each do |event|
        lines << ''
        lines << event.summary
        lines << ('-' * event.summary.length)
        lines << "#{event.date.to_s.strip}, #{event.time}"
        lines << ''
        lines << sanitize(event.description, tags: [])
        location = ''
        location += "#{event.partner_at_location}, " if event.partner_at_location
        location += event.location.to_s
        lines << location
        lines << ''
        lines << "https://placecal.org#{event_path(event)}"
        lines << ''
      end
    end
    lines.join("\n")
  end
end
