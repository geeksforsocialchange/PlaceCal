# frozen_string_literal: true

class Components::Sites::EventFilter < Components::Base
  theme_scope :event_filter,
              parts: {
                toggles: 'The row holding the filter-and-sort toggle and the date toggle, in the day-strip style.',
                filter: 'The wrapper of one filter: the neighbourhood filter or the filter-and-sort menu.',
                form: 'The form inside each filter.',
                toggle: 'The row holding a toggle button: the date picker or the filter-and-sort menu.',
                toggle_button: 'A toggle button. The variant says which; the state says when filter-and-sort has something applied.',
                link: 'The underlined label inside a toggle button, and the Today link.',
                dropdown: 'The filter-and-sort panel. The state says whether it is open.',
                group: 'One group of radio buttons in the panel: sort, period or repeating.',
                option: 'One radio button and its label.',
                applied: 'The line saying what is applied, with its reset link. Only when something is.',
                applied_reset: 'The link that clears what is applied.',
                day_strip: 'The strip of day links, each a pill, ending with All upcoming.',
                day_strip_all: 'The strip\'s last item, holding the All upcoming pill.'
              },
              variants: { toggle_button: %i[date sort], group: %i[sort period repeating] },
              states: { toggle_button: %i[active], dropdown: %i[open closed] },
              tokens: %i[--color-background --color-foreground --color-primary --color-rules --color-rules-dark --font-sans --shadow-dropdown]

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
  # The controller passes its query so the site event scope is not rebuilt just
  # to count the neighbourhood dropdown.
  prop :query, _Nilable(::EventsQuery), default: nil

  # Hidden behind its button; on touch it covers the button so a tap opens the native picker, which iOS won't do from script.
  DATE_INPUT = 'absolute opacity-0 size-0 pointer-events-none pointer-coarse:inset-0 pointer-coarse:size-full pointer-coarse:pointer-events-auto'
  DROPDOWN_RULE = 'border-0 border-t-3'

  # Today, tomorrow and five more days (D22).
  DAY_STRIP_LENGTH = 7

  def after_initialize
    @sort ||= 'time'
    @selected_neighbourhood = @selected_neighbourhood.to_i
  end

  def view_template
    Sites::RegionFilter(tags: @region_tags, selected: @selected_region)
    case Current.theme.event_filter_style
    when :day_strip_with_date_picker
      render_toggles_row
      render_day_strip
      render_applied_filters
      render_neighbourhood_filter if show_neighbourhood_filter?
    when :day_strip
      render_day_strip
      render_neighbourhood_filter if show_neighbourhood_filter?
      render_sort_filter
    else
      render_date_picker
      render_neighbourhood_filter if show_neighbourhood_filter?
      render_sort_filter
    end
  end

  private

  def day_strip_with_date_picker?
    Current.theme.event_filter_style == :day_strip_with_date_picker
  end

  # Both toggles side by side, so a theme can lay them out as one row
  # (#3368: the day-strip-with-date-picker style needs "Filter events" and
  # "Pick a date" next to each other, with the day strip underneath).
  def render_toggles_row
    div(**part(:toggles)) do
      render_sort_filter
      render_date_toggle
    end
  end

  def render_date_picker
    div(**part(:toggle, class: "#{Sites::Filter::TOGGLE} pointer-coarse:relative", data: { controller: 'date-picker' })) do
      render_today_link
      render_goto_date_button
      render_date_picker_fields
    end
  end

  # The day-strip-with-date-picker style's own date toggle: the date picker's
  # button and hidden field, minus the Today link, since the day strip
  # already carries a Today button of its own.
  def render_date_toggle
    div(**part(:toggle, class: "#{Sites::Filter::TOGGLE} pointer-coarse:relative", data: { controller: 'date-picker' })) do
      render_goto_date_button(variant: :date, label: t('filters.pick_a_date'))
      render_date_picker_fields
    end
  end

  def render_today_link
    return if @today

    link_to(t('filters.today'), @today_url, **part(:link, class: "#{Sites::Breadcrumb::LINK} mr-2", data: { turbo_frame: 'events-browser', turbo_action: 'advance' }))
  end

  def render_goto_date_button(variant: nil, label: t('filters.go_to_date'))
    button(**part(:toggle_button, variant:, type: 'button', class: Sites::Filter::TOGGLE_BUTTON, data: { action: 'click->date-picker#open' })) do
      raw(view_context.icon(:triangle_down, size: nil, css_class: Sites::Filter::TOGGLE_ICON))
      whitespace
      span(**part(:link, class: 'border-b-2 border-rules-dark')) { label }
    end
  end

  def render_date_picker_fields
    # The field has no visible label: the Go to date button opens it. The
    # aria-label gives it the same name for assistive tech (axe: label).
    date_field_tag(:date, @pointer, class: DATE_INPUT, aria: { label: t('filters.go_to_date') },
                                    data: { date_picker_target: 'input', action: 'change->date-picker#submit' })
    # id: nil throughout: the neighbourhood and sort filters carry the same
    # three fields, so the default ids appeared twice on /events (axe
    # duplicate-id). The date picker reaches them by Stimulus target.
    # With a day strip the picker selects that one day, as the strip's buttons do.
    hidden_field_tag(:period, day_strip_with_date_picker? ? 'day' : @period, id: nil,
                                                                             data: { date_picker_target: 'period' })
    hidden_field_tag(:sort, @sort, id: nil, data: { date_picker_target: 'sort' })
    hidden_field_tag(:repeating, @repeating, id: nil, data: { date_picker_target: 'repeating' })
    hidden_field_tag(:region, @selected_region.slug, id: nil) if @selected_region
  end

  # D22: Today / Tomorrow / next five days plus "All upcoming", linking to the
  # existing dated event URLs. No new query parameters; sort and repeating ride
  # along only when they differ from the controller defaults.
  def render_day_strip
    nav(**part(:day_strip, class: 'min-w-0 overflow-x-auto', aria: { label: t('filters.day_strip.label') })) do
      UI::Cluster(as: :ul, gap: :sm, align: :stretch, wrap: false, class: 'whitespace-nowrap') do
        day_strip_dates.each_with_index do |date, index|
          li(class: 'shrink-0') { render_day_strip_day(date, index) }
        end
        li(**part(:day_strip_all, class: 'shrink-0')) { render_day_strip_all_upcoming }
      end
    end
  end

  def render_day_strip_day(date, index)
    UI::Pill(variant: :segment, selected: @period == 'day' && @pointer == date, current: 'date', href: day_strip_day_url(date),
             data: { turbo_frame: 'events-browser', turbo_action: 'advance' }) { day_strip_label(date, index) }
  end

  def render_day_strip_all_upcoming
    UI::Pill(variant: :segment, selected: @period == 'future', current: 'true', href: "#{events_path(**day_strip_params, period: 'future')}#paginator",
             data: { turbo_frame: 'events-browser', turbo_action: 'advance' }) { t('filters.day_strip.all_upcoming') }
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

  def render_neighbourhood_filter
    div(**part(:filter, data: { controller: 'event-filter' })) do
      raw(view_context.form_tag('', method: :get, **part(:form, class: 'relative', enforce_utf8: false, data: { turbo_frame: 'events-browser', turbo_action: 'advance' })) do
        safe_join([
          view_context.hidden_field_tag(:period, @period),
          view_context.hidden_field_tag(:sort, @sort),
          view_context.hidden_field_tag(:repeating, @repeating),
          (@selected_region ? view_context.hidden_field_tag(:region, @selected_region.slug, id: nil) : nil),
          view_context.render(Components::Sites::Filter.new(
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
    div(**part(:filter, data: { controller: 'filters' })) do
      raw(build_sort_filter_form)
    end
  end

  def build_sort_filter_form
    view_context.form_tag('', method: :get, **part(:form, class: 'relative', enforce_utf8: false,
                                                          data: { turbo_frame: 'events-browser', turbo_action: 'advance',
                                                                  filters_target: 'form', action: 'change->filters#submit' })) do
      buf = ActiveSupport::SafeBuffer.new
      buf << view_context.hidden_field_tag(:region, @selected_region.slug, id: nil) if @selected_region
      buf << build_sort_toggle
      buf << build_sort_dropdown
      buf
    end
  end

  def build_sort_toggle
    view_context.content_tag(:div, **part(:toggle, class: Sites::Filter::TOGGLE)) do
      view_context.content_tag(:button, **part(:toggle_button, variant: :sort, state: (:active if filters_active?), type: 'button', class: Sites::Filter::TOGGLE_BUTTON,
                                                               data: { action: 'click->filters#toggle' })) do
        safe_join([view_context.icon(:triangle_down, size: nil, css_class: Sites::Filter::TOGGLE_ICON), ' ',
                   view_context.content_tag(:span, t('filters.filter_and_sort'), **part(:link, class: 'border-b-2 border-rules-dark'))])
      end
    end
  end

  # Something other than the defaults is applied, so the closed toggle can say so.
  def filters_active?
    @sort != 'time' || (@repeating.present? && @repeating != 'on') || @period == 'week'
  end

  # What is applied, in words, with a way back to the plain listing. The
  # selected day counts too: the strip has no "all upcoming" on every theme.
  def render_applied_filters
    parts = applied_filters
    return if parts.empty?

    div(**part(:applied)) do
      span { parts.join(', ') }
      link_to(t('filters.applied.reset'), "#{events_path(**region_params)}#paginator",
              **part(:applied_reset, class: Sites::Breadcrumb::LINK, data: { turbo_frame: 'events-browser', turbo_action: 'advance' }))
    end
  end

  def applied_filters
    parts = []
    parts << t('filters.applied.date', date: applied_date_label) if @period == 'day' && @pointer
    parts << t('filters.applied.from_date', date: applied_date_label) if @period != 'day' && pointer_moved?
    parts << t('filters.period.week') if @period == 'week'
    parts << t('filters.applied.sorted_by_name') if @sort == 'summary'
    parts << t('filters.applied.one_off_only') if @repeating == 'off'
    parts << t('filters.applied.repeating_only') if @repeating == 'only'
    parts
  end

  # The date picker lands on a "from this date" listing (period kept), so a
  # pointer off today is a filter even when the period is not a day.
  def pointer_moved?
    @pointer.present? && @pointer != Time.zone.today
  end

  def applied_date_label
    case (@pointer - Time.zone.today).to_i
    when 0 then t('filters.day_strip.today').downcase
    when 1 then t('filters.day_strip.tomorrow').downcase
    else @pointer.strftime(t('filters.applied.date_format'))
    end
  end

  def region_params
    @selected_region ? { region: @selected_region.slug } : {}
  end

  def build_sort_dropdown
    view_context.content_tag(:div, **part(:dropdown, state: :closed, class: Sites::Filter::DROPDOWN, data: { filters_target: 'dropdown' })) do
      render_filter_groups
    end
  end

  def render_filter_groups
    buf = ActiveSupport::SafeBuffer.new
    buf << render_sort_group
    buf << view_context.tag.hr(class: DROPDOWN_RULE)
    buf << render_period_group
    buf << view_context.tag.hr(class: DROPDOWN_RULE)
    buf << render_repeating_group
    buf
  end

  def render_sort_group
    view_context.content_tag(:div, **part(:group, variant: :sort)) do
      render_radio('sort', 'time', @sort == 'time', t('filters.sort.time')) +
        render_radio('sort', 'summary', @sort == 'summary', t('filters.sort.summary'))
    end
  end

  def render_period_group
    view_context.content_tag(:div, **part(:group, variant: :period)) do
      buf = render_radio('period', 'day', @period == 'day', t('filters.period.day')) +
            render_radio('period', 'week', @period == 'week', t('filters.period.week'))
      buf += render_radio('period', 'month', @period == 'month', t('filters.period.month')) if @show_monthly
      buf + render_radio('period', 'future', @period == 'future', t('filters.period.future'))
    end
  end

  def render_repeating_group
    view_context.content_tag(:div, **part(:group, variant: :repeating)) do
      render_radio('repeating', 'on', @repeating == 'on', t('filters.repeating.on')) +
        render_radio('repeating', 'off', @repeating == 'off', t('filters.repeating.off')) +
        render_radio('repeating', 'only', @repeating == 'only', t('filters.repeating.only'))
    end
  end

  def render_radio(name, value, checked, label_text)
    view_context.content_tag(:div, **part(:option, class: Sites::Filter::OPTION)) do
      view_context.radio_button_tag(name, value, checked, class: 'peer') +
        view_context.label_tag("#{name}_#{value}", label_text, class: 'peer-checked:font-bold')
    end
  end

  # Counting future events per neighbourhood for the dropdown was ~100ms a
  # request. Cached with a short TTL, the same tolerance Site#news_article_count
  # already accepts; keyed on the site, period and region so each view caches
  # separately. On a hit the query and its base scope are skipped.
  def neighbourhood_items
    return [] unless @site

    @neighbourhood_items ||= Rails.cache.fetch(['event_facet_neighbourhoods', @site.id, @period, @selected_region&.id],
                                               expires_in: 10.minutes) do
      query = @query || EventsQuery.new(site: @site)
      query.neighbourhoods_with_counts(period: @period, tag_id: @selected_region&.id)
           .map { |n| { id: n[:neighbourhood].id, name: n[:neighbourhood].name, count: n[:count] } }
    end
  end

  def show_neighbourhood_filter?
    Current.theme.event_neighbourhood_filter? && neighbourhood_items.length > 1
  end
end
