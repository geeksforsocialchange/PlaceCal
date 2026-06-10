# frozen_string_literal: true

class Views::Directory::Events::Index < Views::Base
  PERIOD_OPTIONS = [['This week', 'week'], ['Today', 'day'], ['This month', 'month'], ['All upcoming', 'future']].freeze

  prop :events, Hash
  prop :site, _Nilable(::Site)
  prop :period, String, default: 'week'
  prop :current_day, Date
  prop :total_count, Integer, default: 0
  prop :partnerships_list, _Interface(:each), default: -> { [] }
  prop :selected_partnership, _Nilable(String), default: nil
  prop :query, _Nilable(String), default: nil
  prop :pagy, _Nilable(Pagy::Offset), default: nil

  def view_template
    content_for(:title) { 'Events' }
    content_for(:description) { "Discover #{@total_count} upcoming events and activities from community organisations across the UK on PlaceCal." }

    Directory::PageHero(
      title: 'Events on PlaceCal',
      kicker: kicker_text,
      subtitle: 'A nationwide event feed is a lot. Narrow down by place, interest, or partnership to see what\'s coming up near you.',
      breadcrumb_label: 'Events'
    )

    div(class: 'container-public py-6') do
      render_filters
      render_period_tabs
      render_results_header
      render_event_list
      Directory::Paginator(pagy: @pagy) if @pagy
    end
  end

  private

  def kicker_text
    "#{@total_count} upcoming events across the UK"
  end

  def render_filters
    form(action: events_path, method: 'get',
         class: 'bg-home-background-3 rounded-card p-4 mb-4') do
      div(class: 'flex flex-wrap gap-3 items-end') do
        render_search_field
        render_partnership_select
        render_period_select
        render_buttons
      end
    end
  end

  def render_search_field
    div(class: 'flex-1 min-w-50') do
      label(for: 'q', class: 'block allcaps-label text-tertiary mb-1') { 'Search' }
      input(
        type: 'text', name: 'q', id: 'q', value: @query,
        placeholder: 'Event name or keyword…',
        class: 'w-full border-2 border-rules rounded-full px-4 py-2 text-sm bg-background text-foreground outline-none focus:border-foreground transition-colors'
      )
    end
  end

  def render_partnership_select
    return if @partnerships_list.none?

    Directory::CustomSelect(
      name: 'partnership',
      label_text: 'Partnership',
      options: @partnerships_list.map { |item| { id: item[:slug], name: item[:name] } },
      selected: @selected_partnership
    )
  end

  def render_period_select
    Directory::CustomSelect(
      name: 'period',
      label_text: 'Time range',
      options: PERIOD_OPTIONS.map { |label, value| { id: value, name: label } },
      selected: @period,
      include_blank: false
    )
  end

  def render_buttons
    div(class: 'flex gap-2 items-end') do
      button(type: 'submit',
             class: 'bg-foreground text-background rounded-full px-5 py-2 text-sm font-bold border-0 cursor-pointer hover:bg-tertiary transition-colors') do
        plain 'Filter'
      end
      if any_filter_active?
        a(href: events_path,
          class: 'inline-flex items-center rounded-full px-4 py-2 text-sm font-bold text-tertiary border-2 border-rules no-underline hover:border-foreground transition-colors') do
          plain 'Clear'
        end
      end
    end
  end

  def render_period_tabs
    nav(class: 'flex gap-1 flex-wrap py-2', aria_label: 'Time period') do
      [['Today', 'day'], ['This week', 'week'], ['This month', 'month'], ['All upcoming', 'future']].each do |label, value|
        params = current_filter_params.merge('period' => value)
        if @period == value
          span(class: 'inline-flex items-center px-4 py-1.5 rounded-full text-sm font-bold bg-foreground text-background') { label }
        else
          a(href: "#{events_path}?#{params.to_query}",
            class: 'inline-flex items-center px-4 py-1.5 rounded-full text-sm font-bold bg-home-background-3 text-foreground no-underline hover:bg-primary transition-colors') do
            plain label
          end
        end
      end
    end
  end

  def render_results_header
    count = flat_events.size
    div(class: 'text-sm text-tertiary py-2') do
      if count.zero?
        plain "No events #{period_label}"
      else
        plain "#{count} #{'event'.pluralize(count)} #{period_label}"
      end
    end
  end

  def render_event_list
    if flat_events.empty?
      render_empty_state
    else
      @events.each do |date, day_events|
        render_day_group(date, day_events)
      end
    end
  end

  def render_day_group(date, day_events)
    div(class: 'py-3') do
      h2(class: 'font-serif text-lg text-foreground mb-2 pt-2 border-t-2 border-rules') do
        plain date.strftime('%A, %-d %B %Y')
      end
      div(class: 'grid md:grid-cols-2 gap-x-6') do
        day_events.each do |event|
          Directory::EventRow(event: event)
        end
      end
    end
  end

  def render_empty_state
    div(class: 'py-10 text-center') do
      p(class: 'text-tertiary text-lg mb-4') { "No events found #{period_label}." }
      unless @period == 'future'
        a(href: "#{events_path}?period=future",
          class: 'inline-flex items-center gap-2 text-foreground font-bold no-underline hover:underline') do
          plain 'Show all upcoming events'
        end
      end
    end
  end

  def flat_events
    @flat_events ||= @events.values.flatten
  end

  def period_label
    case @period
    when 'day' then 'today'
    when 'week' then 'this week'
    when 'month' then 'this month'
    else ''
    end
  end

  def any_filter_active?
    @query.present? || @selected_partnership.present?
  end

  def current_filter_params
    params = {}
    params['q'] = @query if @query.present?
    params['partnership'] = @selected_partnership if @selected_partnership.present?
    params
  end
end
