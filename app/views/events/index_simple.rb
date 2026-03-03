# frozen_string_literal: true

class Views::Events::IndexSimple < Views::Base
  prop :events, _Any, reader: :private

  def view_template
    if events.any?
      events.each do |day, day_events|
        h2 { day.strftime('%A %e %B') }
        day_events.each do |event|
          p do
            strong { event.summary }
            br
            plain "#{event.date}, #{event.time}"
            br
            plain event.description
            br
            plain "#{event.partner_at_location}, #{event.location}"
            br
            link_to "https://placecal.org#{event_path(event)}", "https://placecal.org#{event_path(event)}"
          end
        end
      end
    else
      plain 'No events with this selection.'
    end
  end
end
