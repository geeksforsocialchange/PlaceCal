# frozen_string_literal: true

class Components::EventList < Components::Base
  prop :events, _Any
  prop :period, _Nilable(_Any), default: nil
  prop :primary_neighbourhood, _Nilable(_Any), default: nil
  prop :show_neighbourhoods, _Boolean, default: false
  prop :badge_zoom_level, _Nilable(_Any), default: nil
  prop :next_date, _Nilable(_Any), default: nil
  prop :site_tagline, _Nilable(String), default: nil
  prop :truncated, _Boolean, default: false

  def view_template # rubocop:disable Metrics/MethodLength
    if @events.any?
      @events.each do |day, day_events|
        h2(class: 'udl udl--fw') { day.strftime('%A %e %B') }
        ol(class: 'events reset') do
          day_events.each do |event|
            li do
              Event(
                display_context: @period,
                event: event,
                primary_neighbourhood: @primary_neighbourhood,
                show_neighbourhoods: @show_neighbourhoods,
                badge_zoom_level: @badge_zoom_level,
                site_tagline: @site_tagline
              )
            end
          end
        end
      end
      p(class: 'event-list__truncated') { 'Showing first 50 events. Use the date picker to see more.' } if @truncated
    else
      p { 'No events with this selection.' }
      p { link_to('Skip to next date with events.', helpers.next_url(@next_date)) } if @next_date.present?
    end
  end
end
