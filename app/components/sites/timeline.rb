# frozen_string_literal: true

class Components::Sites::Timeline < Components::Base
  DEFAULT_STEPS = 7

  LIST = 'paginator__buttons relative grid grid-cols-paginator gap-1 md:gap-2 list-none m-0 px-10 pb-2 font-bold'
  TAB = 'border-2 border-primary rounded-pill text-center hover:bg-primary'
  TAB_LINK = 'with-no-sass text-foreground no-underline flex items-center justify-center size-full py-1 px-4 whitespace-nowrap'
  ARROW = 'paginator__arrow absolute top-0 size-9 p-0 bg-primary hover:bg-foreground'
  ARROW_LINK = 'with-no-sass flex items-center justify-center size-full'
  ARROW_ICON = 'size-4 text-background'

  prop :pointer, _Union(Date, String)
  prop :period, _Nilable(String), default: nil
  prop :sort, _Nilable(String), default: nil
  prop :repeating, _Nilable(String), default: nil
  prop :path, _Nilable(String), default: nil
  prop :show_upcoming, _Boolean, default: false
  prop :date_period, _Nilable(String), default: nil

  def after_initialize
    @pointer = @pointer.respond_to?(:to_date) ? @pointer.to_date : Date.parse(@pointer.to_s)
    @sort ||= 'time'
    @path ||= 'events'
    # date_period controls the stepping for date tabs (week/month/day)
    # Falls back to period when not explicitly set
    @date_period ||= @period == 'upcoming' ? 'month' : @period
  end

  def view_template
    return unless renderable?

    ol(class: LIST, data: { controller: 'paginator' }) do
      buttons.each do |btn|
        li_attrs = { class: btn[:css] }
        btn[:data].each do |k, v|
          li_attrs[:"data-#{k.to_s.dasherize}"] = v
        end
        li(**li_attrs) do
          a(href: btn[:link], class: btn[:link_css], aria_label: btn[:label], data: { turbo_frame: 'events-browser', turbo_action: 'advance' }) do
            if btn[:svg]
              raw(btn[:svg])
            else
              plain btn[:text]
            end
          end
        end
      end
    end
  end

  private

  def renderable?
    %w[day week month upcoming].include?(@period)
  end

  def buttons
    pages = []

    # Arrow pointer: for 'upcoming', use the first visible date tab as the reference
    arrow_ref = @period == 'upcoming' ? window_start : @pointer
    pages << { svg: view_context.icon(:triangle_left, size: nil, css_class: ARROW_ICON), link: url_for(step_back(arrow_ref)), label: t('components.timeline.earlier'),
               css: "#{ARROW} left-0", link_css: "#{ARROW_LINK} pr-0.5", data: {} }

    if @show_upcoming
      pages << { text: t('components.timeline.upcoming'), link: upcoming_url, css: tab_class(@period == 'upcoming'), link_css: TAB_LINK,
                 data: { paginator_target: 'button' } }
    end

    current = window_start
    date_steps.times do
      pages << { text: format_date(current), link: url_for(current), css: tab_class(date_tab_active?(current)), link_css: TAB_LINK,
                 data: { paginator_target: 'button' } }
      current = step_forward(current)
    end

    pages << { svg: view_context.icon(:triangle_right, size: nil, css_class: ARROW_ICON), link: url_for(step_forward(arrow_ref)), label: t('components.timeline.later'),
               css: "#{ARROW} right-0", link_css: "#{ARROW_LINK} pl-0.5", data: { paginator_target: 'forward' } }
  end

  def tab_class(active)
    active ? "#{TAB} active bg-primary" : TAB
  end

  def date_steps
    @show_upcoming ? DEFAULT_STEPS - 1 : DEFAULT_STEPS
  end

  def date_tab_active?(date)
    return false if @period == 'upcoming'

    same_step?(date, @pointer)
  end

  def step
    case @date_period
    when 'month' then 1.month
    when 'week' then 1.week
    else 1.day
    end
  end

  def step_forward(date)
    @date_period == 'month' ? (date >> 1).beginning_of_month : date + step
  end

  def step_back(date)
    @date_period == 'month' ? (date << 1).beginning_of_month : date - step
  end

  def same_step?(date, other)
    if @date_period == 'month'
      date.year == other.year && date.month == other.month
    else
      date == other
    end
  end

  def window_start
    today = Time.zone.today

    if @date_period == 'month'
      pointer_month = @pointer.beginning_of_month
      today_month = today.beginning_of_month
      window_end = today_month >> (date_steps - 1)

      if pointer_month <= today_month
        # Pointer is in the past — start from pointer
        pointer_month
      elsif pointer_month <= window_end
        # Pointer fits in window starting from today
        today_month
      else
        # Pointer is beyond the default window — shift so pointer is the last tab
        pointer_month << (date_steps - 1)
      end
    else
      center_offset = (date_steps - 1) / 2

      if @pointer <= today
        [@pointer, today].min
      elsif @pointer <= today + (center_offset * step)
        today
      else
        @pointer - (center_offset * step)
      end
    end
  end

  def format_date(date)
    case @date_period
    when 'month' then monthify(date)
    when 'week' then weekify(date)
    else todayify(date)
    end
  end

  def todayify(date)
    today = Time.zone.today
    return t('components.timeline.today') if date == today
    return t('components.timeline.tomorrow') if date == today + 1.day

    I18n.l(date, format: :timeline_day)
  end

  def monthify(date)
    today = Time.zone.today
    return t('components.timeline.this_month') if date.year == today.year && date.month == today.month

    I18n.l(date, format: date.year == today.year ? :timeline_month : :timeline_month_year)
  end

  def weekify(date)
    today = Time.zone.today
    end_date = date + step - 1.day

    return t('components.timeline.next_7_days') if date == today

    from = I18n.l(date, format: date.month == end_date.month ? :timeline_week_start : :timeline_day_month)
    t('components.timeline.week', from:, to: I18n.l(end_date, format: :timeline_day_month))
  end

  def upcoming_url
    today = Time.zone.today
    "/#{@path}/#{today.year}/#{today.month}/#{today.day}?period=upcoming&sort=#{@sort}&repeating=#{@repeating}#paginator"
  end

  def url_for(date)
    d = date.respond_to?(:year) ? date : date.to_date
    period_for_url = @date_period
    if @date_period == 'month'
      today = Time.zone.today
      d = d.year == today.year && d.month == today.month ? today : d.beginning_of_month
    end
    "/#{@path}/#{d.year}/#{d.month}/#{d.day}?period=#{period_for_url}&sort=#{@sort}&repeating=#{@repeating}#paginator"
  end
end
