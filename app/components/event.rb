# frozen_string_literal: true

class Components::Event < Components::Base
  prop :display_context, _Nilable(Symbol), default: nil
  prop :event, _Interface(:summary, :dtstart)  # Event model or test double
  prop :primary_neighbourhood, _Nilable(::Neighbourhood), default: nil
  prop :show_neighbourhoods, _Boolean, default: false
  prop :badge_zoom_level, _Nilable(String), default: nil
  prop :site_tagline, _Nilable(String), default: nil
  # When rendered on a partner page, set this to that partner so we don't
  # redundantly show "By X" or "at X" when X is the page we're already on.
  prop :context_partner, _Nilable(::Partner), default: nil

  def view_template
    div(class: "event #{page? ? 'event--full' : 'event--list'}") do
      article do
        page? ? render_page_layout : render_list_layout
      end
    end
  end

  private

  def render_page_layout
    Hero(summary, @site_tagline)
    div(class: 'c') { render_event_details }
  end

  def render_list_layout
    render_list_header
    render_event_details
  end

  delegate :id, :partner_at_location, :summary, :description, to: :@event

  def render_list_header
    div(class: 'event__header') do
      h3(itemprop: 'name') { link_to(summary, event_path(id), data: { turbo_frame: '_top' }) }
      if neighbourhood_name && @show_neighbourhoods
        css = "neighbourhood #{primary_neighbourhood? ? 'neighbourhood--primary' : 'neighbourhood--secondary'} event__neighbourhood"
        div(class: css) { span { neighbourhood_name } }
      end
    end
  end

  def render_event_details
    div(class: 'event__details') do
      render_detail('event__time', :event_time, time)
      render_detail('event__duration', :event_duration, duration) if duration
      render_detail('event__date', :event_date, date)
      render_detail('event__repeats', :event_repeats, repeats) if repeats
      render_detail('event__repeats', :event_online, 'Online') if online?
      render_organiser if show_organiser?
      render_place if show_place?
    end
  end

  def render_detail(css, icon_name, text)
    div(class: "event__detail #{css}") do
      raw(view_context.icon(icon_name, size: nil))
      plain " #{text}"
    end
  end

  # Show organiser row when:
  # - the event has an organiser
  # - organiser is different from the place (otherwise place row is enough)
  # - organiser is not the context_partner (we're already on their page)
  def show_organiser?
    organiser = @event.respond_to?(:organiser) ? @event.organiser : nil
    organiser.present? && organiser != partner_at_location && organiser != @context_partner
  end

  # Show place row when:
  # - the event has a place or address
  # - the place is not the context_partner (we're already on their page)
  def show_place?
    return false unless partner_at_location || first_address_line
    return true unless @context_partner

    partner_at_location != @context_partner
  end

  def render_organiser
    organiser = @event.organiser
    div(class: 'event__detail event__organiser') do
      raw(view_context.icon(:partner, size: nil))
      plain ' '
      link_to(truncate(organiser.name, length: 30), partner_path(organiser), data: { turbo_frame: '_top' })
    end
  end

  def render_place
    div(class: 'event__detail event__location') do
      raw(view_context.icon(:event_place, size: nil))
      plain ' '
      if partner_at_location
        link_to(truncate(partner_at_location.name, length: 30), partner_path(partner_at_location), data: { turbo_frame: '_top' })
      elsif first_address_line
        plain truncate(first_address_line, length: 30)
      end
    end
  end

  def time
    if @event.dtend
      "#{fmt_time(@event.dtstart)} \u2013 #{fmt_time(@event.dtend)}"
    else
      fmt_time(@event.dtstart)
    end
  end

  def duration
    return false unless @event.dtend

    mins = ((@event.dtend - @event.dtstart) / 60).to_i
    hours = mins / 60

    if hours < 25
      mins_str = (mins % 60).positive? ? "#{mins % 60} mins" : ''
      hours_str = hours.positive? ? pluralize(hours, 'hour') : ''
      [hours_str, mins_str].reject(&:empty?).join(' ')
    else
      distance_of_time_in_words(@event.dtend - @event.dtstart)
    end
  end

  def formatted_date(date)
    if date.year == Time.zone.now.year
      date.strftime('%e %b')
    else
      date.strftime('%e %b %Y')
    end
  end

  def date
    return formatted_date(@event.dtstart) if @event.dtend.blank?

    if @event.dtstart.to_date == @event.dtend.to_date
      formatted_date(@event.dtstart)
    else
      "#{formatted_date(@event.dtstart)} - #{formatted_date(@event.dtend)}"
    end
  end

  def page?
    @display_context == :page
  end

  def first_address_line
    @event.address&.street_address&.delete('\\')
  end

  def repeats
    @event.rrule.present? ? @event.rrule[0]['table']['frequency'].titleize : false
  end

  def neighbourhood_name
    @event.neighbourhood&.name_from_badge_zoom(@badge_zoom_level)
  end

  def primary_neighbourhood?
    return true unless @primary_neighbourhood

    @event.neighbourhood == @primary_neighbourhood || @primary_neighbourhood.children.include?(@event.neighbourhood)
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
