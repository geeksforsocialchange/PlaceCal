# frozen_string_literal: true

class TimelineComponent < ViewComponent::Base
  include SvgIconsHelper

  DEFAULT_STEPS = 7

  def initialize(pointer:, period:, sort:, repeating:, path:)
    super()
    @pointer = pointer.respond_to?(:to_date) ? pointer.to_date : Date.parse(pointer.to_s)
    @period = period
    @sort = sort || 'time'
    @repeating = repeating
    @path = path || 'events'
  end

  attr_reader :pointer, :period, :sort, :repeating, :path

  def render?
    %w[day week].include?(period)
  end

  def buttons
    pages = []
    pages << { text: back_arrow, link: url_for(pointer - step), css: 'paginator__arrow paginator__arrow--back', data: {} }
    (0..steps).each do |i|
      day = window_start + (step * i)
      css = day == pointer ? 'active' : ''
      pages << { text: format_date(day), link: url_for(day), css: css, data: { paginator_target: 'button' } }
    end
    pages << { text: forward_arrow, link: url_for(pointer + step), css: 'paginator__arrow paginator__arrow--forwards', data: { paginator_target: 'forward' } }
  end

  private

  def step
    period == 'week' ? 1.week : 1.day
  end

  def steps
    DEFAULT_STEPS - 1
  end

  def window_start
    today = Time.zone.today
    center_offset = steps / 2

    if pointer <= today
      [pointer, today].min
    elsif pointer <= today + (center_offset * step)
      today
    else
      pointer - (center_offset * step)
    end
  end

  def format_date(date)
    step <= 1.day ? todayify(date) : weekify(date)
  end

  def todayify(date)
    today = Time.zone.today
    return 'Today' if date == today
    return 'Tomorrow' if date == today + 1.day

    date.strftime('%a %e %b')
  end

  def weekify(date)
    today = Time.zone.today
    end_date = date + step - 1.day

    return 'Next 7 days' if date == today

    if date.month == end_date.month
      "#{date.strftime('%e')} - #{end_date.strftime('%e %b')}"
    else
      "#{date.strftime('%e %b')} – #{end_date.strftime('%e %b')}"
    end
  end

  def url_for(date)
    d = date.respond_to?(:year) ? date : date.to_date
    "/#{path}/#{d.year}/#{d.month}/#{d.day}?period=#{period}&sort=#{sort}&repeating=#{repeating}#paginator"
  end

  def back_arrow
    icon(:triangle_left, css_class: 'text-base-background')
  end

  def forward_arrow
    icon(:triangle_right, css_class: 'text-base-background')
  end
end
