# frozen_string_literal: true

class Components::Directory::EventRow < Components::Directory::Base
  include Components::Shared::EventRowDetails
  include Components::Shared::LongRunningDates
  include Components::Shared::TicketDetails

  prop :event, _Interface(:summary, :dtstart)
  prop :context_partner, _Nilable(::Partner), default: nil

  def view_template
    div(class: 'grid grid-cols-date-row gap-4 items-start py-3 border-b border-rules') do
      render_date_badge
      render_body
    end
  end

  private

  def called_off? = Shared::EventStatus.called_off?(@event)

  def render_date_badge
    div(class: "font-serif text-center bg-home-background-3 rounded-sm py-1 px-2#{' line-through' if called_off?}") do
      div(class: 'text-2xl leading-none font-regular') { @event.dtstart.day.to_s }
      div(class: 'font-sans text-2xs uppercase tracking-wide text-tertiary font-extra-bold mt-1') do
        plain @event.dtstart.strftime('%b').upcase
      end
    end
  end

  def render_body
    div do
      div(class: 'font-bold text-lg leading-tight mb-1') do
        link_to(@event.summary, event_path(@event),
                class: "text-foreground #{called_off? ? 'line-through' : 'no-underline hover:border-b-2 hover:border-primary'}",
                data: { turbo_frame: '_top' })
      end
      div(class: 'flex flex-wrap gap-x-3 gap-y-1 text-sm text-tertiary') do
        render_meta_status if called_off?
        render_meta_time
        render_meta_place if show_place?
        render_meta_organiser if show_organiser?
        render_meta_repeats if repeats
        render_meta_online if @event.online_address.present?
        render_meta_tickets if ticket_label
      end
    end
  end

  def render_meta_status
    span(class: 'inline-flex items-center gap-1') do
      render_icon(:event_status)
      Shared::EventStatus(event: @event)
    end
  end

  def render_meta_time
    span(class: "inline-flex items-center gap-1#{' line-through' if called_off?}") do
      render_icon(:event_time)
      long_running?(@event) ? render_until : render_time_range
    end
  end

  def render_time_range
    time(datetime: @event.dtstart.iso8601) { fmt_time(@event.dtstart) }
    return unless @event.dtend && @event.dtend != @event.dtstart

    plain ' – '
    time(datetime: @event.dtend.iso8601) { fmt_time(@event.dtend) }
  end

  def render_until
    time(datetime: @event.dtend.iso8601) { until_text(@event) }
  end

  def render_meta_place
    span(class: 'inline-flex items-center gap-1') do
      render_icon(:event_place)
      partner = @event.partner_at_location
      if partner
        UI::Link(href: partner_path(partner), data: { turbo_frame: '_top' }) { truncated(partner.name, 30) }
      elsif @event.address&.street_address
        truncated(@event.address.street_address.delete('\\'), 30)
      end
    end
  end

  def render_meta_organiser
    span(class: 'inline-flex items-center gap-1') do
      render_icon(:partner)
      UI::Link(href: partner_path(@event.organiser), data: { turbo_frame: '_top' }) { truncated(@event.organiser.name, 25) }
    end
  end

  def render_meta_repeats
    span(class: 'inline-flex items-center gap-1') do
      render_icon(:event_repeats)
      plain repeats
    end
  end

  def render_meta_online
    span(class: 'inline-flex items-center gap-1') do
      render_icon(:event_online)
      plain @event.online_address.service_name || t('directory.event_row.online')
    end
  end

  def render_meta_tickets
    span(class: 'inline-flex items-center gap-1') do
      render_icon(:ticket)
      plain ticket_label
    end
  end

  # Raleway's glyphs sit below the middle of their line box, so a centred icon looks high without the nudge
  def render_icon(name)
    raw(view_context.icon(name, size: nil, css_class: 'w-3.5 h-3.5 translate-y-px text-tertiary opacity-55 shrink-0'))
  end
end
