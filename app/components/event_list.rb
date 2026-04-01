# frozen_string_literal: true

class Components::EventList < Components::Base
  prop :events, Hash
  prop :period, _Nilable(String), default: nil
  prop :primary_neighbourhood, _Nilable(::Neighbourhood), default: nil
  prop :show_neighbourhoods, _Boolean, default: false
  prop :badge_zoom_level, _Nilable(String), default: nil
  prop :next_date, _Nilable(Time), default: nil
  prop :site_tagline, _Nilable(String), default: nil
  prop :truncated, _Boolean, default: false
  prop :context_partner, _Nilable(::Partner), default: nil

  def view_template
    @events.any? ? render_events : render_empty_state
  end

  private

  def render_events
    @events.each do |day, day_events|
      h2(class: 'udl udl--fw') { day.strftime('%A %e %B') }
      render_day(day_events)
    end
    p(class: 'event-list__truncated') { 'Showing first 50 events. Use the date picker to see more.' } if @truncated
  end

  def render_day(day_events)
    ol(class: 'events reset') do
      day_events.each do |event|
        li { render_event(event) }
      end
    end
  end

  def render_event(event)
    Event(
      display_context: @period&.to_sym,
      event: event,
      primary_neighbourhood: @primary_neighbourhood,
      show_neighbourhoods: @show_neighbourhoods,
      badge_zoom_level: @badge_zoom_level,
      site_tagline: @site_tagline,
      context_partner: @context_partner
    )
  end

  def render_empty_state
    p { 'No events with this selection.' }
    p { link_to('Skip to next date with events.', next_url(@next_date)) } if @next_date.present?
  end
end
