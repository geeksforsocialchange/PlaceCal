# frozen_string_literal: true

class PaginatorComponent < ViewComponent::Base
  include SvgIconsHelper

  DEFAULT_STEPS = 7

  # rubocop:disable Metrics/ParameterLists
  def initialize(pointer:, period:, sort: nil, repeating: nil, path: nil, steps: nil, show_breadcrumb: true, site_name: nil)
    # rubocop:enable Metrics/ParameterLists
    super()
    @raw_pointer = pointer
    @period = period
    @raw_sort = sort
    @repeating = repeating
    @raw_path = path
    @raw_steps = steps
    @show_breadcrumb = show_breadcrumb
    @site_name = site_name
  end

  attr_reader :period, :repeating, :show_breadcrumb, :site_name

  # Link array
  def paginator
    pages = []
    pages << { text: back_arrow,
               link: create_event_url(pointer - step),
               css: 'paginator__arrow paginator__arrow--back',
               data: {} }
    (0..steps).each do |i|
      day = window_start + (step * i)
      css = active?(day) ? 'active' : ''
      pages << { text: format_date(day),
                 link: create_event_url(day),
                 css: css,
                 data: { paginator_target: 'button' } }
    end
    pages << { text: forward_arrow,
               link: create_event_url(pointer + step),
               css: 'paginator__arrow paginator__arrow--forwards',
               data: { paginator_target: 'forward' } }
  end

  # The start of the visible window of dates
  # Initially today is on the left, but after navigating far enough right,
  # the selection becomes centered in the window
  def window_start
    today = Time.zone.today
    center_offset = steps / 2

    if pointer <= today
      # At or before today: show today on left, pointer will be at or before left edge
      [pointer, today].min
    elsif pointer <= today + (center_offset * step)
      # Close to today: keep today on left so selection moves right
      today
    else
      # Far from today: center the selection in the window
      pointer - (center_offset * step)
    end
  end

  def title
    if step <= 1.day
      pointer.strftime('%A %e %B, %Y')
    else
      t = pointer.strftime('%A %e %B')
      t += ' - '
      t + (pointer + step - 1.day).strftime('%A %e %B %Y')
    end
  end

  def sort
    @raw_sort || 'time'
  end

  def step
    period == 'week' ? 1.week : 1.day
  end

  def path
    @raw_path || 'events'
  end

  def steps
    (@raw_steps || DEFAULT_STEPS) - 1
  end

  def pointer
    @raw_pointer
  end

  def today?
    pointer == Time.zone.today
  end

  def today_url
    today = Time.zone.today
    "/#{path}/#{today.year}/#{today.month}/#{today.day}#{url_suffix}#paginator"
  end

  private

  def format_date(date)
    if step <= 1.day
      todayify(date)
    else
      weekify(date)
    end
  end

  def todayify(date)
    today = Time.zone.today
    date_fmt = date.strftime('%a %e %b')
    if date == today
      'Today'
    elsif date == today + 1.day
      'Tomorrow'
    else
      date_fmt
    end
  end

  def weekify(date)
    today = Time.zone.today
    end_date = date + step - 1.day

    # Show "Next 7 days" for the period starting today
    if date == today
      'Next 7 days'
    elsif date.month == end_date.month
      "#{date.strftime('%e')} - #{end_date.strftime('%e %b')}"
    else
      "#{date.strftime('%e %b')} – #{end_date.strftime('%e %b')}"
    end
  end

  def create_event_url(date_time)
    "/#{path}/#{date_time.year}/#{date_time.month}/#{date_time.day}#{url_suffix}#paginator"
  end

  def url_suffix
    str = []
    str << "period=#{period}"
    str << "sort=#{sort}" if sort
    str << "repeating=#{repeating}" if repeating
    "?#{str.join('&')}" if str.any?
  end

  def back_arrow
    icon(:triangle_left, size: '0')
  end

  def forward_arrow
    icon(:triangle_right, size: '0')
  end

  def active?(day)
    pointer == day
  end
end
