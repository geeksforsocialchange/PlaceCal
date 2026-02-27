# frozen_string_literal: true

class Components::Timeline < Components::Base
  DEFAULT_STEPS = 7

  prop :pointer, _Union(Date, String)
  prop :period, _Nilable(String), default: nil
  prop :sort, _Nilable(String), default: nil
  prop :repeating, _Nilable(String), default: nil
  prop :path, _Nilable(String), default: nil

  def after_initialize
    @pointer = @pointer.respond_to?(:to_date) ? @pointer.to_date : Date.parse(@pointer.to_s)
    @sort ||= 'time'
    @path ||= 'events'
  end

  def view_template
    return unless %w[day week].include?(@period)

    ol(class: 'paginator__buttons paginator__buttons--day', data: { controller: 'paginator' }) do
      buttons.each do |btn|
        li_attrs = { class: btn[:css] }
        btn[:data].each do |k, v|
          li_attrs[:"data-#{k.to_s.dasherize}"] = v
        end
        li(**li_attrs) do
          link_to(raw(safe(btn[:text])), btn[:link], data: { turbo_frame: 'events-browser', turbo_action: 'advance' })
        end
      end
    end
  end

  private

  def buttons
    pages = []
    pages << { text: back_arrow, link: url_for(@pointer - step), css: 'paginator__arrow paginator__arrow--back', data: {} }
    (0..steps).each do |i|
      day = window_start + (step * i)
      css = day == @pointer ? 'active' : ''
      pages << { text: format_date(day), link: url_for(day), css: css, data: { paginator_target: 'button' } }
    end
    pages << { text: forward_arrow, link: url_for(@pointer + step), css: 'paginator__arrow paginator__arrow--forwards', data: { paginator_target: 'forward' } }
  end

  def step
    @period == 'week' ? 1.week : 1.day
  end

  def steps
    DEFAULT_STEPS - 1
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
      "#{date.strftime('%e %b')} \u2013 #{end_date.strftime('%e %b')}"
    end
  end

  def url_for(date)
    d = date.respond_to?(:year) ? date : date.to_date
    "/#{@path}/#{d.year}/#{d.month}/#{d.day}?period=#{@period}&sort=#{@sort}&repeating=#{@repeating}#paginator"
  end

  def back_arrow
    '<span class="icon icon--arrow-left-grey">&larr;</span>'
  end

  def forward_arrow
    '<span class="icon icon--arrow-right-grey">&rarr;</span>'
  end
end
