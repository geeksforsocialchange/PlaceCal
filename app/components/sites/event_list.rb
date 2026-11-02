# frozen_string_literal: true

class Components::Sites::EventList < Components::Base
  theme_scope :event_list,
              parts: {
                day: 'One day\'s list of events, under its date heading.',
                item: 'One event in a day\'s list, holding its card.',
                truncated: 'The line saying only the first events are shown. Only when the list is cut short.',
                empty: 'A line of the empty state: that there are no events, then a link to the next date with events when there is one.'
              },
              tokens: %i[]

  prop :events, Hash
  prop :period, _Nilable(String), default: nil
  prop :show_neighbourhoods, _Boolean, default: false
  prop :badge_zoom_level, _Nilable(String), default: nil
  prop :next_date, _Nilable(Time), default: nil
  prop :site_tagline, _Nilable(String), default: nil
  prop :truncated, _Boolean, default: false
  prop :context_partner, _Nilable(::Partner), default: nil
  # Under a section heading (the partner page), so day headings and titles drop a size.
  prop :nested, _Boolean, default: false

  def view_template
    @events.any? ? render_events : render_empty_state
  end

  private

  def render_events
    @events.each do |day, day_events|
      UI::RuledHeading(rule: :full, size: (@nested ? :lg : :inherit)) { I18n.l(day, format: :event_day) }
      render_day(day_events)
    end
    p(**part(:truncated)) { t('components.event_list.truncated') } if @truncated
  end

  def render_day(day_events)
    ol(**part(:day, class: 'reset')) do
      day_events.each do |event|
        li(**part(:item, class: 'block w-full')) { render_event(event) }
      end
    end
  end

  def render_event(event)
    Sites::Event(
      display_context: @period&.to_sym,
      event:,
      show_neighbourhoods: @show_neighbourhoods,
      badge_zoom_level: @badge_zoom_level,
      site_tagline: @site_tagline,
      context_partner: @context_partner,
      nested: @nested
    )
  end

  def render_empty_state
    p(**part(:empty)) { t('components.event_list.empty') }
    p(**part(:empty)) { link_to(t('components.event_list.skip_to_next'), next_url(@next_date)) } if @next_date.present?
  end
end
