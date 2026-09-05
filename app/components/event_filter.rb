# frozen_string_literal: true

class Components::EventFilter < Components::Base
  prop :pointer, Date
  prop :period, _Nilable(String), default: nil
  prop :sort, _Nilable(String), default: nil
  prop :repeating, _Nilable(String), default: nil
  prop :today_url, String
  prop :today, _Boolean, default: false
  prop :site, _Nilable(::Site), default: nil
  prop :selected_neighbourhood, _Nilable(String), default: nil
  prop :show_monthly, _Boolean, default: true
  prop :region_tags, Array, default: -> { [] }
  prop :selected_region, _Nilable(::Tag), default: nil

  # Today, tomorrow and five more days (D22).
  DAY_STRIP_LENGTH = 7

  def after_initialize
    @sort ||= 'time'
    @selected_neighbourhood = @selected_neighbourhood.to_i
  end

  def view_template
    RegionFilter(tags: @region_tags, selected: @selected_region)
    if Current.theme.event_filter_style == :day_strip
      render_day_strip
    else
      render_date_picker
    end
    render_neighbourhood_filter if show_neighbourhood_filter?
    render_sort_filter
  end

  private

  def render_date_picker
    div(class: 'filters__toggle', data: { controller: 'date-picker' }) do
      render_today_link
      render_goto_date_button
      render_date_picker_fields
    end
  end

  def render_today_link
    return if @today

    link_to(t('filters.today'), @today_url, class: 'filters__link filters__link--today', data: { turbo_frame: 'events-browser', turbo_action: 'advance' })
  end

  def render_goto_date_button
    button(type: 'button', data: { action: 'click->date-picker#open' }) do
      raw(view_context.icon(:triangle_down, size: nil))
      plain ' '
      span(class: 'filters__link') { t('filters.go_to_date') }
    end
  end

  def render_date_picker_fields
    date_field_tag(:date, @pointer, class: 'filters__date-input', data: { date_picker_target: 'input', action: 'change->date-picker#submit' })
    hidden_field_tag(:period, @period, data: { date_picker_target: 'period' })
    hidden_field_tag(:sort, @sort, data: { date_picker_target: 'sort' })
    hidden_field_tag(:repeating, @repeating, data: { date_picker_target: 'repeating' })
    hidden_field_tag(:region, @selected_region.slug, id: nil) if @selected_region
  end

  # D22: Today / Tomorrow / next five days plus "All upcoming", linking to the
  # existing dated event URLs. No new query parameters; sort and repeating ride
  # along only when they differ from the controller defaults.
  def render_day_strip
    nav(class: 'day-strip min-w-0 overflow-x-auto', aria: { label: t('filters.day_strip.label') }) do
      ul(class: 'flex list-none gap-2 whitespace-nowrap p-0 m-0') do
        day_strip_dates.each_with_index do |date, index|
          li(class: 'shrink-0') { render_day_strip_day(date, index) }
        end
        li(class: 'shrink-0') { render_day_strip_all_upcoming }
      end
    end
  end

  def render_day_strip_day(date, index)
    current = @period == 'day' && @pointer == date
    link_to(day_strip_label(date, index),
            day_strip_day_url(date),
            class: day_strip_link_class(current),
            aria: { current: current ? 'date' : nil },
            data: { turbo_frame: 'events-browser', turbo_action: 'advance' })
  end

  def render_day_strip_all_upcoming
    current = @period == 'future'
    link_to(t('filters.day_strip.all_upcoming'),
            "#{events_path(**day_strip_params, period: 'future')}#paginator",
            class: day_strip_link_class(current),
            aria: { current: current ? 'true' : nil },
            data: { turbo_frame: 'events-browser', turbo_action: 'advance' })
  end

  def day_strip_dates
    today = Time.zone.today
    (0...DAY_STRIP_LENGTH).map { |offset| today + offset }
  end

  def day_strip_label(date, index)
    case index
    when 0 then t('filters.day_strip.today')
    when 1 then t('filters.day_strip.tomorrow')
    else date.strftime(t('filters.day_strip.date_format'))
    end
  end

  def day_strip_day_url(date)
    path = events_by_date_path(year: date.year, month: date.month, day: date.day,
                               period: 'day', **day_strip_params)
    "#{path}#paginator"
  end

  # The selected region is sticky across the day strip, so it rides along on
  # every day link and on "All upcoming" (#3368 D20).
  def day_strip_params
    params = {}
    params[:sort] = @sort if @sort.present? && @sort != 'time'
    params[:repeating] = @repeating if @repeating.present? && @repeating != 'on'
    params[:region] = @selected_region.slug if @selected_region
    params
  end

  def day_strip_link_class(current)
    base = 'day-strip__link with-no-sass inline-flex items-center rounded-sm border-2 px-3 py-1.5 text-sm font-bold no-underline transition-colors'
    state = if current
              'bg-foreground text-background border-foreground'
            else
              'bg-background text-foreground border-rules hover:border-foreground'
            end
    "#{base} #{state}"
  end

  def render_neighbourhood_filter
    div(class: 'filters', data: { controller: 'event-filter' }) do
      raw(view_context.form_tag('', method: :get, class: 'filters__form', enforce_utf8: false, data: { turbo_frame: 'events-browser', turbo_action: 'advance' }) do
        safe_join([
          view_context.hidden_field_tag(:period, @period),
          view_context.hidden_field_tag(:sort, @sort),
          view_context.hidden_field_tag(:repeating, @repeating),
          (@selected_region ? view_context.hidden_field_tag(:region, @selected_region.slug, id: nil) : nil),
          view_context.render(Components::Filter.new(
                                name: 'neighbourhood',
                                label: t('filters.neighbourhood'),
                                items: neighbourhood_items,
                                selected_id: @selected_neighbourhood,
                                controller: 'event-filter',
                                toggle_action: 'toggleNeighbourhood',
                                submit_action: 'submitNeighbourhood',
                                reset_action: 'resetNeighbourhood'
                              ))
        ].compact)
      end)
    end
  end

  def render_sort_filter
    div(class: 'filters', data: { controller: 'filters' }) do
      raw(build_sort_filter_form)
    end
  end

  def build_sort_filter_form
    view_context.form_tag('', method: :get, class: 'filters__form', enforce_utf8: false, data: { turbo_frame: 'events-browser', turbo_action: 'advance', filters_target: 'form', action: 'change->filters#submit' }) do
      buf = ActiveSupport::SafeBuffer.new
      buf << view_context.hidden_field_tag(:region, @selected_region.slug, id: nil) if @selected_region
      buf << build_sort_toggle
      buf << build_sort_dropdown
      buf
    end
  end

  def build_sort_toggle
    view_context.content_tag(:div, class: 'filters__toggle') do
      view_context.content_tag(:button, type: 'button', data: { action: 'click->filters#toggle' }) do
        safe_join([view_context.icon(:triangle_down, size: nil), ' ', view_context.content_tag(:span, t('filters.filter_and_sort'), class: 'filters__link')])
      end
    end
  end

  def build_sort_dropdown
    view_context.content_tag(:div, class: 'filters__dropdown filters__dropdown--hidden', data: { filters_target: 'dropdown' }) do
      render_filter_groups
    end
  end

  def render_filter_groups
    buf = ActiveSupport::SafeBuffer.new
    buf << render_sort_group
    buf << view_context.tag.hr
    buf << render_period_group
    buf << view_context.tag.hr
    buf << render_repeating_group
    buf
  end

  def render_sort_group
    view_context.content_tag(:div, class: 'filters__group') do
      render_radio('sort', 'time', @sort == 'time', t('filters.sort.time')) +
        render_radio('sort', 'summary', @sort == 'summary', t('filters.sort.summary'))
    end
  end

  def render_period_group
    view_context.content_tag(:div, class: 'filters__group') do
      buf = render_radio('period', 'day', @period == 'day', t('filters.period.day')) +
            render_radio('period', 'week', @period == 'week', t('filters.period.week'))
      buf += render_radio('period', 'month', @period == 'month', t('filters.period.month')) if @show_monthly
      buf + render_radio('period', 'future', @period == 'future', t('filters.period.future'))
    end
  end

  def render_repeating_group
    view_context.content_tag(:div, class: 'filters__group') do
      render_radio('repeating', 'on', @repeating == 'on', t('filters.repeating.on')) +
        render_radio('repeating', 'last', @repeating == 'last', t('filters.repeating.last')) +
        render_radio('repeating', 'off', @repeating == 'off', t('filters.repeating.off'))
    end
  end

  def render_radio(name, value, checked, label_text)
    view_context.content_tag(:div, class: 'filters__option') do
      view_context.radio_button_tag(name, value, checked) +
        view_context.label_tag("#{name}_#{value}", label_text)
    end
  end

  def neighbourhoods
    return [] unless @site

    @neighbourhoods ||= EventsQuery.new(site: @site).neighbourhoods_with_counts(period: @period, tag_id: @selected_region&.id)
  end

  def neighbourhood_items
    neighbourhoods.map do |n|
      { id: n[:neighbourhood].id, name: n[:neighbourhood].name, count: n[:count] }
    end
  end

  def show_neighbourhood_filter?
    neighbourhoods.length > 1
  end
end
