# frozen_string_literal: true

class Components::Sites::Event < Components::Base
  theme_scope :event,
              parts: %i[root header title neighbourhood details time duration date repeats online organiser organiser_prefix place icon],
              variants: { root: %i[card page] },
              states: { root: %i[online] },
              tokens: %i[--color-foreground --color-secondary --color-rules --text-detail --text-md]

  prop :display_context, _Nilable(Symbol), default: nil
  prop :event, _Interface(:summary, :dtstart)  # Event model or test double
  prop :show_neighbourhoods, _Boolean, default: false
  prop :badge_zoom_level, _Nilable(String), default: nil
  prop :site_tagline, _Nilable(String), default: nil
  # When rendered on a partner page, set this to that partner so we don't
  # redundantly show "By X" or "at X" when X is the page we're already on.
  prop :context_partner, _Nilable(::Partner), default: nil
  # [label, path] back link, threaded through to Hero on the page layout
  # (Views::Events::Show renders its hero here, not directly).
  prop :back, _Nilable(Array), default: nil
  # Under a day heading that is itself under a section heading, so the title drops a size.
  prop :nested, _Boolean, default: false

  ICON = 'size-7 mr-1 text-secondary'

  def view_template
    div(**part(:root, variant: page? ? :page : :card, states: { online: online? }, class: 'h-event mb-8')) do
      page? ? render_page_layout : render_list_layout
    end
  end

  private

  def render_page_layout
    Shared::Hero(summary, @site_tagline, section: t('events.show.section'), back: @back, standfirst: organiser_line)
    a(class: 'p-name u-url', href: event_path(id), hidden: true) { summary }
    div(class: 'container-public') { render_event_details }
  end

  def render_list_layout
    render_list_header
    render_event_details
  end

  delegate :id, :partner_at_location, :summary, :description, to: :@event

  def render_list_header
    div(**part(:header, class: 'grid md:grid-cols-main-auto md:items-center')) do
      h3(**part(:title, class: "inline-block mb-2.5#{' text-md' if @nested}")) do
        link_to(summary, event_path(id), class: 'p-name u-url text-foreground no-underline', data: { turbo_frame: '_top' })
      end
      div(**part(:neighbourhood, class: 'max-md:hidden')) { UI::Pill(variant: :neighbourhood, class: 'mt-3') { neighbourhood_name } } if neighbourhood_name && @show_neighbourhoods
    end
  end

  def render_event_details
    div(**part(:details, class: "flex flex-wrap items-center gap-x-4 gap-y-1 text-detail border-rules py-2 md:py-3 #{page? ? 'border-b-10' : 'border-y-3'}")) do
      render_time_detail
      render_detail(:duration, :event_duration, duration) if duration
      render_date_detail
      render_detail(:repeats, :event_repeats, repeats) if repeats
      render_detail(:online, :event_online, t('events.card.online')) if online?
      render_organiser if show_organiser?
      render_place if show_place?
      render_detail(:neighbourhood, :neighbourhood, neighbourhood_line) if page? && @event.neighbourhood
    end
  end

  def render_time_detail
    div(**detail(:time)) do
      render_icon(:event_time)
      whitespace
      time(class: 'dt-start', datetime: @event.dtstart.iso8601) { fmt_time(@event.dtstart) }
      if @event.dtend
        plain " \u2013 "
        time(class: 'dt-end', datetime: @event.dtend.iso8601) { end_time }
      end
    end
  end

  def render_date_detail
    div(**detail(:date)) do
      render_icon(:event_date)
      whitespace
      plain date
    end
  end

  def render_detail(name, icon_name, text)
    div(**detail(name)) do
      render_icon(icon_name)
      whitespace
      plain text
    end
  end

  def detail(name, css = nil)
    part(name, class: ['flex items-center', ('max-md:hidden' if name == :duration), css].compact.join(' '))
  end

  def render_icon(name)
    raw(view_context.icon(name, size: nil, css_class: ICON, **part(:icon)))
  end

  def show_organiser?
    organiser = @event.try(:organiser)
    return false if organiser.blank?
    return false if organiser == partner_at_location  # place row already shows it
    return false if organiser == @context_partner      # we're on their page

    true
  end

  def show_place?
    return false if partner_at_location.blank? && first_address_line.blank?
    return true if @context_partner.blank?  # no context to suppress against

    partner_at_location != @context_partner  # hide if we're on the place's page
  end

  def render_organiser
    organiser = @event.organiser
    div(**detail(:organiser)) do
      render_icon(:partner)
      whitespace
      # Optional prefix such as "by ", blank in core; themes set it.
      prefix = t('events.card.organiser_prefix')
      span(**part(:organiser_prefix)) { prefix } if prefix.present?
      # The card truncates to keep its row; the page has room for the whole name.
      link_to(page? ? organiser.name : organiser.name.truncate(25), partner_path(organiser), data: { turbo_frame: '_top' })
    end
  end

  def render_place
    div(**detail(:place, 'p-location')) do
      render_icon(:event_place)
      whitespace
      if partner_at_location
        link_to(partner_at_location.name.truncate(25), partner_path(partner_at_location), data: { turbo_frame: '_top' })
      elsif first_address_line
        plain first_address_line.truncate(25)
      end
    end
  end

  def duration
    return false unless @event.dtend

    mins = ((@event.dtend - @event.dtstart) / 60).to_i
    hours = mins / 60

    if hours < 25
      mins_str = (mins % 60).positive? ? t('events.card.duration_minutes', count: mins % 60) : ''
      hours_str = hours.positive? ? t('events.card.duration_hours', count: hours) : ''
      [hours_str, mins_str].reject(&:empty?).join(' ')
    else
      distance_of_time_in_words(@event.dtend - @event.dtstart)
    end
  end

  # Formats come from locale keys so a theme can change them (for example a
  # zero-padded day for a big numeral treatment) through theme_overrides.
  # The page layout has its own keys. `%o` stands for the ordinal day (2nd).
  def formatted_date(date)
    scope = page? ? 'events.page' : 'events.card'
    key = date.year == Time.zone.now.year ? 'date_format' : 'date_format_with_year'
    date.strftime(t("#{scope}.#{key}").gsub('%o', date.day.ordinalize))
  end

  # Always the start day; a multi-day event shows its end date on the time line instead.
  def date
    formatted_date(@event.dtstart)
  end

  def end_time
    return fmt_time(@event.dtend) unless multi_day?

    scope = page? ? 'events.page' : 'events.card'
    "#{@event.dtend.strftime(t("#{scope}.end_date_format"))} #{fmt_time(@event.dtend).strip}"
  end

  def multi_day?
    @event.dtend.present? && @event.dtend - @event.dtstart >= 1.day
  end

  def page?
    @display_context == :page
  end

  def first_address_line
    @event.address&.street_address&.delete('\\')
  end

  # The frequency comes from the calendar feed (RFC 5545 FREQ), so an
  # unmapped value falls back to the raw word rather than a missing key.
  def repeats
    frequency = ::Event.rrule_frequency(@event.rrule)
    return false if frequency.blank?

    t("events.card.frequency.#{frequency.downcase}", default: frequency.titleize)
  end

  # "By <organiser>" under the title, the name linked; the hero's standfirst slot is free here.
  def organiser_line
    organiser = @event.organiser
    organiser && t('events.show.by_organiser_html', name: view_context.link_to(organiser.name, partner_path(organiser), class: UI::Link.css(tone: :inherit)))
  end

  def neighbourhood_line
    [@event.neighbourhood.shortname, @event.neighbourhood.district&.shortname].compact.join(', ')
  end

  def neighbourhood_name
    @event.neighbourhood&.name_from_badge_zoom(@badge_zoom_level)
  end

  def online?
    @event.online_address.present?
  end

  def fmt_time(time)
    if time.strftime('%M') == '00'
      time.strftime('%l%P')
    else
      time.strftime('%l:%M%P')
    end
  end
end
