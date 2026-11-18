# frozen_string_literal: true

class Components::Sites::Event < Components::Base
  theme_scope :event,
              parts: {
                root: 'The whole event: a card in a listing, the top of the page on the event\'s own page (see the variant).',
                content: 'The width-limited column under the hero that holds the details row. Page variant only.',
                header: 'The card\'s title row: the title and the neighbourhood badge. Card variant only.',
                title: 'The card\'s h3, holding the link to the event. Card variant only.',
                neighbourhood: 'The neighbourhood badge in the card\'s header, holding a pill. Only when the listing shows neighbourhoods.',
                details: 'The row of detail lines.',
                detail: 'One detail line, its icon then its text; the variant says which. Each line only when the event has it.',
                organiser_prefix: 'Optional words before the organiser\'s name, such as "by ", inside the organiser detail. Blank in core; a theme fills it.',
                icon: 'The svg icon at the start of each detail line.',
                status_notice: 'On the event\'s own page, the line saying it\'s cancelled or postponed; the variant says which. Only for an event that is called off.'
              },
              variants: { root: %i[card page], detail: %i[status time duration date repeats online organiser place],
                          status_notice: Components::Shared::EventStatus::CALLED_OFF.map(&:to_sym) },
              states: { root: %i[online] },
              tokens: %i[--color-foreground --color-primary --color-secondary --color-rules --text-detail --text-xl --text-lg --text-md --font-weight-bold]

  prop :display_context, _Nilable(Symbol), default: nil
  prop :event, _Interface(:summary, :dtstart)  # Event model or test double
  prop :show_neighbourhoods, _Boolean, default: false
  prop :badge_zoom_level, _Nilable(String), default: nil
  prop :site_tagline, _Nilable(String), default: nil
  # When rendered on a partner page, set this to that partner so we don't
  # redundantly show "By X" or "at X" when X is the page we're already on.
  prop :context_partner, _Nilable(::Partner), default: nil
  # Under a day heading that is itself under a section heading, so the title drops a size.
  prop :nested, _Boolean, default: false
  # Core themes leave the organiser to the details row; extension themes put it under the title
  prop :organiser_byline, _Boolean, default: true
  # Core event pages say Online on Zoom; elsewhere the row names just the service
  prop :online_on, _Boolean, default: false

  ICON = 'size-7 mr-1 text-secondary'

  def view_template
    div(**part(:root, variant: page? ? :page : :card, state: (:online if online?), class: 'h-event mb-8')) do
      page? ? render_page_layout : render_list_layout
    end
  end

  private

  def render_page_layout
    Shared::Hero(summary, @site_tagline, section: t('events.show.section'), struck: called_off?, standfirst: (organiser_line if @organiser_byline))
    a(class: 'p-name u-url', href: event_path(id), hidden: true) { summary }
    div(**part(:content, class: 'container-public')) do
      render_status_notice
      render_event_details
    end
  end

  def render_list_layout
    render_list_header
    render_event_details
  end

  delegate :id, :partner_at_location, :summary, :description, to: :@event

  def render_list_header
    div(**part(:header, class: 'grid md:grid-cols-main-auto md:items-center')) do
      h3(**part(:title, class: "inline-block mb-2.5#{' text-md' if @nested}")) do
        link_to(summary, event_path(id), class: "p-name u-url text-foreground #{called_off? ? 'line-through' : 'no-underline'}", data: { turbo_frame: '_top' })
      end
      div(**part(:neighbourhood, class: 'max-md:hidden')) { UI::Pill(variant: :neighbourhood, class: 'mt-3') { neighbourhood_name } } if neighbourhood_name && @show_neighbourhoods
    end
  end

  def called_off? = Shared::EventStatus.called_off?(@event)

  def struck_class = ('line-through' if called_off?)

  def render_status_notice
    return unless called_off?

    p(**part(:status_notice, variant: @event.status.to_sym, class: 'mt-5 mb-0 text-lg font-bold')) { t("events.show.status_notice.#{@event.status}") }
  end

  def render_event_details
    div(**part(:details, class: "flex flex-wrap items-center gap-x-4 gap-y-1 text-detail border-rules py-2 md:py-3 #{page? ? 'border-b-10' : 'border-y-3'}")) do
      render_status_detail if called_off? && !page?
      render_date_detail
      render_time_detail
      render_detail(:duration, :event_duration, duration) if duration
      render_detail(:repeats, :event_repeats, repeats) if repeats
      render_detail(:online, :event_online, online_label) if online?
      render_organiser if show_organiser?
      render_place if show_place?
    end
  end

  # The page says so in a sentence above the details instead
  def render_status_detail
    div(**detail(:status)) do
      render_icon(:event_status)
      whitespace
      Shared::EventStatus(event: @event)
    end
  end

  def render_time_detail
    div(**detail(:time, struck_class)) do
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
    div(**detail(:date, struck_class)) do
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
    part(:detail, variant: name, class: ['flex items-center', ('max-md:hidden' if name == :duration), css].compact.join(' '))
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
      a(href: partner_path(organiser), data: { turbo_frame: '_top' }) { page? ? plain(organiser.name) : truncated(organiser.name, 25) }
    end
  end

  def render_place
    div(**detail(:place, 'p-location')) do
      render_icon(:event_place)
      whitespace
      if partner_at_location
        a(href: partner_path(partner_at_location), data: { turbo_frame: '_top' }) { truncated(partner_at_location.name, 25) }
      elsif first_address_line
        truncated(first_address_line, 25)
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

  def neighbourhood_name
    @event.neighbourhood&.name_from_badge_zoom(@badge_zoom_level)
  end

  def online_label
    service = @event.online_address.service_name
    return t('events.card.online') unless service

    @online_on ? t('events.card.online_on', service:) : service
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
