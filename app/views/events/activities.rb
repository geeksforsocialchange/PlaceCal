# frozen_string_literal: true

class Views::Events::Activities < Views::Base
  prop :events, Hash, reader: :private
  prop :current_day, Date, reader: :private
  prop :next_week, Date, reader: :private
  prop :previous_week, Date, reader: :private
  prop :site, Site, reader: :private

  def view_template
    p(id: 'notice') { view_context.notice }

    h1 do
      plain "Activities from #{current_day.strftime('%A %e %B')} "
      raw safe('&mdash; ')
      plain (next_week - 1.day).strftime('%A %e %B, %Y')
    end

    ol(class: 'paginator paginator--day reset') do
      li { link_to '← Previous Week', "/activities/#{previous_week.year}/#{previous_week.month}/#{previous_week.day}" }
      li { link_to 'Next Week →', "/activities/#{next_week.year}/#{next_week.month}/#{next_week.day}" }
    end

    if events.any?
      ol(class: 'events reset') do
        events.each do |event|
          li(class: 'event') do
            Event(
              display_context: :week,
              event: event,
              primary_neighbourhood: site.primary_neighbourhood,
              show_neighbourhoods: site.show_neighbourhoods?,
              site_tagline: site.tagline
            )
          end
        end
      end
    else
      p { 'No events this week' }
    end
  end
end
