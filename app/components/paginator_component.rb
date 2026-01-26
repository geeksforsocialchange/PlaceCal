# frozen_string_literal: true

class PaginatorComponent < ViewComponent::Base
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
               css: 'paginator__arrow paginator__arrow--back js-back' }
    (0..steps).each do |i|
      day = pointer + (step * i)
      css = active?(day) ? 'active js-button' : 'js-button'
      pages << { text: format_date(day),
                 link: create_event_url(day),
                 css: css }
    end
    pages << { text: forward_arrow,
               link: create_event_url(pointer + step),
               css: 'paginator__arrow paginator__arrow--forwards js-forwards' }
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
    if step == 1.week
      @raw_pointer.beginning_of_week
    else
      @raw_pointer
    end
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
    date_fmt = if date.month == end_date.month
                 "#{date.strftime('%e')} - #{end_date.strftime('%e %b')}"
               else
                 "#{date.strftime('%e %b')} – #{end_date.strftime('%e %b')}"
               end
    if date == today.beginning_of_week
      'This week'
    else
      date_fmt
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
    '<span class="icon icon--arrow-left-grey">←</span>'.html_safe # rubocop:disable Rails/OutputSafety
  end

  def forward_arrow
    '<span class="icon icon--arrow-right-grey">→</span>'.html_safe # rubocop:disable Rails/OutputSafety
  end

  def active?(day)
    pointer == day
  end
end
