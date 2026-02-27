# frozen_string_literal: true

class Components::Event < Components::Base
  prop :display_context, _Any
  prop :event, _Any
  prop :primary_neighbourhood, _Nilable(_Any), default: nil
  prop :show_neighbourhoods, _Boolean, default: false
  prop :badge_zoom_level, _Nilable(_Any), default: nil
  prop :site_tagline, _Nilable(String), default: nil

  def view_template # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    div(class: "event #{page? ? 'event--full' : 'event--list'}") do
      article do
        if page?
          Hero(summary, @site_tagline)
          div(class: 'c') do
            render_event_details
          end
        else
          render_list_header
          render_event_details
        end
      end
    end
  end

  private

  delegate :id, :partner_at_location, :summary, :description, to: :@event

  def render_list_header
    div(class: 'event__header') do
      h3(itemprop: 'name') { link_to(summary, helpers.event_path(id), data: { turbo_frame: '_top' }) }
      if neighbourhood_name && @show_neighbourhoods
        css = "neighbourhood #{primary_neighbourhood? ? 'neighbourhood--primary' : 'neighbourhood--secondary'} event__neighbourhood"
        div(class: css) { span { neighbourhood_name } }
      end
    end
  end

  def render_event_details # rubocop:disable Metrics/MethodLength
    div(class: 'event__details') do
      render_detail('event__time', 'icon-time', time)
      render_detail('event__duration', 'icon-duration', duration) if duration
      render_detail('event__date', 'icon-date', date)
      render_detail('event__repeats', 'icon-online', 'Online') if online?
      render_location if partner_at_location || first_address_line
      render_detail('event__repeats', 'icon-repeats', repeats) if repeats
    end
  end

  def render_detail(css, icon_css, text)
    div(class: "event__detail #{css}") do
      span(class: "icon-font #{icon_css}")
      plain " #{text}"
    end
  end

  def render_location
    div(class: 'event__detail event__location') do
      span(class: 'icon-font icon-place')
      if partner_at_location
        plain ' '
        link_to(partner_at_location, helpers.partner_path(partner_at_location), data: { turbo_frame: '_top' })
      elsif first_address_line
        plain " #{first_address_line}"
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
      hours_str = hours.positive? ? helpers.pluralize(hours, 'hour') : ''
      [hours_str, mins_str].reject(&:empty?).join(' ')
    else
      helpers.distance_of_time_in_words(@event.dtend - @event.dtstart)
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
