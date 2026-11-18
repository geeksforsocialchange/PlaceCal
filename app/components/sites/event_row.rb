# frozen_string_literal: true

# One event as a row: a date badge, then the title and a line of details. The directory's row in the site's style.
class Components::Sites::EventRow < Components::Base
  include Components::Shared::EventRowDetails

  theme_scope :event_row,
              parts: {
                root: 'The whole row: the date badge beside the title and details.',
                date: 'The date badge, holding the day and the month.',
                day: 'The day of the month, in the date badge.',
                month: 'The month, in the date badge.',
                title: 'The title line: the event\'s title, a link to the event, and its neighbourhood badge.',
                neighbourhood: 'The neighbourhood badge, holding a pill. Only when the site shows neighbourhoods.',
                details: 'The line of details under the title.',
                detail: 'One detail, its icon then its text; the variant says which. Each only when the event has it.',
                icon: 'The svg icon at the start of each detail.'
              },
              variants: { detail: %i[time place organiser repeats online] },
              states: { root: Components::Shared::EventStatus::CALLED_OFF.map(&:to_sym) },
              tokens: %i[--color-foreground --color-primary --color-secondary --color-rules --radius-sm --text-2xl --text-2xs --text-lg --text-sm
                         --leading-none --leading-tight --font-weight-bold --font-weight-extra-bold --tracking-wide]

  # A called-off event's date and details fade behind its status and struck-through title
  FADED = ' opacity-70'

  prop :event, _Interface(:summary, :dtstart)
  prop :context_partner, _Nilable(::Partner), default: nil
  prop :show_neighbourhoods, _Boolean, default: false
  prop :badge_zoom_level, _Nilable(String), default: nil

  def view_template
    div(**part(:root, state: (@event.status.to_sym if called_off?), class: 'h-event grid grid-cols-date-row gap-4 items-start py-3')) do
      render_date
      div do
        div(**part(:title, class: 'flex items-center justify-between gap-3 font-bold text-lg leading-tight pb-1.5 mb-1.5 border-b-3 border-rules')) do
          span(class: 'flex flex-wrap items-baseline gap-x-2') do
            Shared::EventStatus(event: @event)
            link_to(@event.summary, event_path(@event), class: "p-name u-url text-foreground #{called_off? ? 'line-through' : 'no-underline hover:underline'}",
                                                        data: { turbo_frame: '_top' })
          end
          span(**part(:neighbourhood, class: 'max-md:hidden shrink-0')) { UI::Pill(variant: :neighbourhood) { neighbourhood_name } } if neighbourhood_name
        end
        render_details
      end
    end
  end

  private

  def render_date
    time(**part(:date, class: "dt-start block text-center bg-rules rounded-sm py-1.5 px-2#{FADED if called_off?}"), datetime: @event.dtstart.iso8601) do
      span(**part(:day, class: 'block text-2xl font-bold leading-none')) { @event.dtstart.day.to_s }
      span(**part(:month, class: 'block text-2xs uppercase tracking-wide font-extra-bold mt-1')) { I18n.l(@event.dtstart, format: '%b') }
    end
  end

  def render_details
    div(**part(:details, class: "flex flex-wrap gap-x-4 gap-y-1 text-sm#{FADED if called_off?}")) do
      detail(:time, :event_time) { time_range }
      detail(:place, :event_place) { place_name } if show_place?
      detail(:organiser, :partner) { UI::Link(href: partner_path(@event.organiser), variant: :thin, data: { turbo_frame: '_top' }) { truncated(@event.organiser.name, 25) } } if show_organiser?
      detail(:repeats, :event_repeats) { plain repeats } if repeats
      detail(:online, :event_online) { plain online_label } if @event.online_address.present?
    end
  end

  def called_off? = Shared::EventStatus.called_off?(@event)

  def online_label
    service = @event.online_address.service_name
    service ? t('events.card.online_on', service:) : t('events.card.online')
  end

  def detail(name, icon_name, &)
    span(**part(:detail, variant: name, class: 'inline-flex items-center gap-1')) do
      raw(view_context.icon(icon_name, size: nil, css_class: 'size-5 text-secondary shrink-0', **part(:icon)))
      yield
    end
  end

  def time_range
    plain fmt_time(@event.dtstart)
    plain " – #{fmt_time(@event.dtend)}" if @event.dtend && @event.dtend != @event.dtstart
  end

  def neighbourhood_name
    @event.neighbourhood&.name_from_badge_zoom(@badge_zoom_level) if @show_neighbourhoods
  end

  def place_name
    partner = @event.partner_at_location
    if partner
      UI::Link(href: partner_path(partner), variant: :thin, data: { turbo_frame: '_top' }) { truncated(partner.name, 30) }
    else
      plain truncated(@event.address.street_address.delete('\\'), 30)
    end
  end
end
