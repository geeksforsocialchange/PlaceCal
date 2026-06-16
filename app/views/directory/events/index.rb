# frozen_string_literal: true

class Views::Directory::Events::Index < Views::Base
  # Period values in the order they appear in the filter dropdown and the tab bar
  # respectively. Labels come from the `directory.events.index.periods` locale.
  SELECT_PERIODS = %w[week day month future].freeze
  TAB_PERIODS = %w[day week month future].freeze

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
    content_for(:title) { ::Event.model_name.human(count: 2) }
    content_for(:description) { t('directory.events.index.description', count: @total_count) }

    Directory::PageHero(
      title: t('directory.events.index.hero_title'),
      kicker: kicker_text,
      subtitle: t('directory.events.index.hero_subtitle'),
      breadcrumb_label: ::Event.model_name.human(count: 2)
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
    t('directory.events.index.kicker', count: @total_count)
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
      label(for: 'q', class: 'block allcaps-label text-tertiary mb-1') { t('directory.filters.search') }
      input(
        type: 'text', name: 'q', id: 'q', value: @query,
        placeholder: t('directory.events.index.search_placeholder'),
        class: 'w-full border-2 border-rules rounded-full px-4 py-2 text-sm bg-background text-foreground outline-none focus:border-foreground transition-colors'
      )
    end
  end

  def render_partnership_select
    return if @partnerships_list.none?

    Directory::CustomSelect(
      name: 'partnership',
      label_text: t('directory.filters.partnership'),
      options: @partnerships_list.map { |item| { id: item[:slug], name: item[:name] } },
      selected: @selected_partnership
    )
  end

  def render_period_select
    Directory::CustomSelect(
      name: 'period',
      label_text: t('directory.events.index.period_label'),
      options: SELECT_PERIODS.map { |value| { id: value, name: period_option_label(value) } },
      selected: @period,
      include_blank: false
    )
  end

  def render_buttons
    div(class: 'flex gap-2 items-end') do
      button(type: 'submit',
             class: 'bg-foreground text-background rounded-full px-5 py-2 text-sm font-bold border-0 cursor-pointer hover:bg-tertiary transition-colors') do
        plain t('directory.filters.apply')
      end
      if any_filter_active?
        a(href: events_path,
          class: 'inline-flex items-center rounded-full px-4 py-2 text-sm font-bold text-tertiary border-2 border-rules no-underline hover:border-foreground transition-colors') do
          plain t('directory.filters.clear')
        end
      end
    end
  end

  def render_period_tabs
    nav(class: 'flex gap-1 flex-wrap py-2', aria_label: t('directory.aria.time_period')) do
      TAB_PERIODS.each do |value|
        label = period_option_label(value)
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
        plain t('directory.events.index.results.none', period: period_phrase)
      else
        plain t('directory.events.index.results.count', count: count, period: period_phrase)
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
      p(class: 'text-tertiary text-lg mb-4') { t('directory.events.index.empty', period: period_phrase) }
      unless @period == 'future'
        a(href: "#{events_path}?period=future",
          class: 'inline-flex items-center gap-2 text-foreground font-bold no-underline hover:underline') do
          plain t('directory.events.index.show_all')
        end
      end
    end
  end

  def flat_events
    @flat_events ||= @events.values.flatten
  end

  def period_option_label(value)
    t("directory.events.index.periods.#{value}")
  end

  # Sentence fragment (with a leading space) appended to the results header,
  # e.g. " this week". Blank for the "future" period.
  def period_phrase
    t("directory.events.index.period_phrases.#{@period}", default: '')
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
