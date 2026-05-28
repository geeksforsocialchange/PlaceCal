# frozen_string_literal: true

class Components::Directory::EventRow < Components::Directory::Base
  prop :event, _Interface(:summary, :dtstart)
  prop :context_partner, _Nilable(::Partner), default: nil

  def view_template
    div(class: 'grid grid-cols-[64px_1fr] gap-4 items-start py-3 border-b border-rules') do
      render_date_badge
      render_body
    end
  end

  private

  def render_date_badge
    div(class: 'font-serif text-center bg-home-background-3 rounded-lg py-1 px-2') do
      div(class: 'text-[1.7rem] leading-none font-regular tracking-tight') { @event.dtstart.day.to_s }
      div(class: 'font-sans text-2xs uppercase tracking-widest text-tertiary font-extra-bold mt-1') do
        plain @event.dtstart.strftime('%b').upcase
      end
    end
  end

  def render_body
    div do
      div(class: 'font-bold text-lg leading-tight mb-1') do
        link_to(@event.summary, event_path(@event),
                class: 'no-underline text-foreground hover:border-b-2 hover:border-primary',
                data: { turbo_frame: '_top' })
      end
      div(class: 'flex flex-wrap gap-x-3 gap-y-0.5 text-sm text-tertiary') do
        render_meta_time
        render_meta_place if show_place?
        render_meta_organiser if show_organiser?
        render_meta_repeats if repeats
        render_meta_online if @event.online_address.present?
      end
    end
  end

  def render_meta_time
    span(class: 'inline-flex items-center gap-1') do
      render_icon(:event_time)
      time(datetime: @event.dtstart.iso8601) { fmt_time(@event.dtstart) }
      if @event.dtend && @event.dtend != @event.dtstart
        plain ' – '
        time(datetime: @event.dtend.iso8601) { fmt_time(@event.dtend) }
      end
    end
  end

  def render_meta_place
    span(class: 'inline-flex items-center gap-1') do
      render_icon(:event_place)
      partner = @event.partner_at_location
      if partner
        link_to(partner.name.truncate(30), partner_path(partner),
                class: 'text-foreground underline decoration-primary decoration-2 underline-offset-2 hover:text-foreground/80',
                data: { turbo_frame: '_top' })
      elsif @event.address&.street_address
        plain @event.address.street_address.delete('\\').truncate(30)
      end
    end
  end

  def render_meta_organiser
    span(class: 'inline-flex items-center gap-1') do
      render_icon(:partner)
      link_to(@event.organiser.name.truncate(25), partner_path(@event.organiser),
              class: 'text-foreground underline decoration-primary decoration-2 underline-offset-2 hover:text-foreground/80',
              data: { turbo_frame: '_top' })
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
      plain 'Online'
    end
  end

  def render_icon(name)
    raw(view_context.icon(name, size: nil, css_class: 'w-3.5 h-3.5 text-tertiary opacity-55 shrink-0'))
  end

  def show_place?
    partner = @event.partner_at_location
    address = @event.address&.street_address
    return false if partner.blank? && address.blank?
    return true if @context_partner.blank?

    partner != @context_partner
  end

  def show_organiser?
    organiser = @event.try(:organiser)
    return false if organiser.blank?
    return false if organiser == @event.partner_at_location
    return false if organiser == @context_partner

    true
  end

  def repeats
    @event.rrule.present? ? @event.rrule[0]['table']['frequency'].titleize : nil
  end

  def fmt_time(time)
    time.strftime('%M') == '00' ? time.strftime('%l%P').strip : time.strftime('%l:%M%P').strip
  end
end
