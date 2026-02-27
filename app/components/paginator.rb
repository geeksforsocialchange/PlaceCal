# frozen_string_literal: true

class Components::Paginator < Components::Base
  DEFAULT_STEPS = 7

  prop :pointer, Date
  prop :period, String
  prop :sort, _Nilable(String), default: nil
  prop :repeating, _Nilable(String), default: nil
  prop :path, _Nilable(String), default: nil
  prop :num_steps, _Nilable(Integer), default: nil
  prop :show_breadcrumb, _Boolean, default: true
  prop :site_name, _Nilable(String), default: nil

  def after_initialize
    @sort ||= 'time'
    @path ||= 'events'
  end

  def view_template
    div(class: 'paginator', id: 'paginator', data: { controller: 'paginator' }) do
      @show_breadcrumb ? render_breadcrumb_context : render_plain_context
      render_paginator_buttons if @period == 'day' || @period == 'week'
    end
  end

  attr_reader :pointer, :sort, :path

  def render_breadcrumb_context
    div(class: 'paginator__context') do
      Breadcrumb(trail: [['Events', events_path]], site_name: @site_name) do
        div(class: 'breadcrumb__actions') { render_event_filter }
      end
    end
  end

  def render_plain_context
    div(class: 'paginator__actions') { render_event_filter }
  end

  def render_event_filter
    EventFilter(
      pointer: @pointer, period: @period, sort: @sort,
      repeating: @repeating, today_url: today_url, today: today?
    )
  end

  def render_paginator_buttons
    ol(class: 'paginator__buttons paginator__buttons--day') do
      paginator_links.each do |page|
        render_paginator_button(page)
      end
    end
  end

  def render_paginator_button(page)
    li_attrs = { class: page[:css] }
    page[:data].each { |k, v| li_attrs[:"data-#{k.to_s.dasherize}"] = v }
    li(**li_attrs) do
      link_to(raw(safe(page[:text])), page[:link], data: { turbo_frame: 'events-browser', turbo_action: 'advance' })
    end
  end

  def step
    @period == 'week' ? 1.week : 1.day
  end

  def steps
    (@num_steps || DEFAULT_STEPS) - 1
  end

  def today?
    @pointer == Time.zone.today
  end

  def today_url
    today = Time.zone.today
    "/#{@path}/#{today.year}/#{today.month}/#{today.day}#{url_suffix}#paginator"
  end

  def window_start
    today = Time.zone.today
    center_offset = steps / 2

    if @pointer <= today
      [@pointer, today].min
    elsif @pointer <= today + (center_offset * step)
      today
    else
      @pointer - (center_offset * step)
    end
  end

  private

  def paginator_links
    pages = []
    pages << { text: back_arrow, link: create_event_url(@pointer - step), css: 'paginator__arrow paginator__arrow--back', data: {} }
    (0..steps).each do |i|
      day = window_start + (step * i)
      css = active?(day) ? 'active' : ''
      pages << { text: format_date(day), link: create_event_url(day), css: css, data: { paginator_target: 'button' } }
    end
    pages << { text: forward_arrow, link: create_event_url(@pointer + step), css: 'paginator__arrow paginator__arrow--forwards', data: { paginator_target: 'forward' } }
  end

  def title
    if step <= 1.day
      @pointer.strftime('%A %e %B, %Y')
    else
      t = @pointer.strftime('%A %e %B')
      t += ' - '
      t + (@pointer + step - 1.day).strftime('%A %e %B %Y')
    end
  end

  def format_date(date)
    step <= 1.day ? todayify(date) : weekify(date)
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

    if date == today
      'Next 7 days'
    elsif date.month == end_date.month
      "#{date.strftime('%e')} - #{end_date.strftime('%e %b')}"
    else
      "#{date.strftime('%e %b')} \u2013 #{end_date.strftime('%e %b')}"
    end
  end

  def create_event_url(date_time)
    "/#{@path}/#{date_time.year}/#{date_time.month}/#{date_time.day}#{url_suffix}#paginator"
  end

  def url_suffix
    str = []
    str << "period=#{@period}"
    str << "sort=#{@sort}" if @sort
    str << "repeating=#{@repeating}" if @repeating
    "?#{str.join('&')}" if str.any?
  end

  def back_arrow
    '<span class="icon icon--arrow-left-grey">&larr;</span>'
  end

  def forward_arrow
    '<span class="icon icon--arrow-right-grey">&rarr;</span>'
  end

  def active?(day)
    @pointer == day
  end
end
