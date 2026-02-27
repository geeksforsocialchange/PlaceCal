# frozen_string_literal: true

class Components::EventFilter < Components::Base
  prop :pointer, Date
  prop :period, String
  prop :sort, _Nilable(String), default: nil
  prop :repeating, _Nilable(String), default: nil
  prop :today_url, String
  prop :today, _Boolean, default: false
  prop :site, _Nilable(::Site), default: nil
  prop :selected_neighbourhood, _Nilable(String), default: nil

  def after_initialize
    @sort ||= 'time'
    @selected_neighbourhood = @selected_neighbourhood.to_i
  end

  def view_template # rubocop:disable Metrics/MethodLength
    render_date_picker
    render_neighbourhood_filter if show_neighbourhood_filter?
    render_sort_filter
  end

  private

  def render_date_picker # rubocop:disable Metrics/MethodLength
    div(class: 'filters__toggle', data: { controller: 'date-picker' }) do
      link_to('Today', @today_url, class: 'filters__link filters__link--today', data: { turbo_frame: 'events-browser', turbo_action: 'advance' }) unless @today
      button(type: 'button', data: { action: 'click->date-picker#open' }) do
        span(class: 'icon icon--arrow-down') { plain "\u2193" }
        plain ' '
        span(class: 'filters__link') { 'Go to date' }
      end
      date_field_tag(:date, @pointer, class: 'filters__date-input', data: { date_picker_target: 'input', action: 'change->date-picker#submit' })
      hidden_field_tag(:period, @period, data: { date_picker_target: 'period' })
      hidden_field_tag(:sort, @sort, data: { date_picker_target: 'sort' })
      hidden_field_tag(:repeating, @repeating, data: { date_picker_target: 'repeating' })
    end
  end

  def render_neighbourhood_filter
    div(class: 'filters', data: { controller: 'event-filter' }) do
      raw safe(view_context.form_tag('', method: :get, class: 'filters__form', enforce_utf8: false, data: { turbo_frame: 'events-browser', turbo_action: 'advance' }) {
        safe_join([
                    view_context.hidden_field_tag(:period, @period),
                    view_context.hidden_field_tag(:sort, @sort),
                    view_context.hidden_field_tag(:repeating, @repeating),
                    view_context.render(Components::Filter.new(
                                          name: 'neighbourhood',
                                          label: 'Neighbourhood',
                                          items: neighbourhood_items,
                                          selected_id: @selected_neighbourhood,
                                          controller: 'event-filter',
                                          toggle_action: 'toggleNeighbourhood',
                                          submit_action: 'submitNeighbourhood',
                                          reset_action: 'resetNeighbourhood'
                                        ))
                  ])
      })
    end
  end

  def render_sort_filter # rubocop:disable Metrics/MethodLength
    div(class: 'filters', data: { controller: 'filters' }) do
      raw safe(view_context.form_tag('', method: :get, class: 'filters__form', enforce_utf8: false, data: { turbo_frame: 'events-browser', turbo_action: 'advance', filters_target: 'form', action: 'change->filters#submit' }) {
        buf = ActiveSupport::SafeBuffer.new
        buf << view_context.content_tag(:div, class: 'filters__toggle') {
          view_context.content_tag(:button, type: 'button', data: { action: 'click->filters#toggle' }) {
            view_context.content_tag(:span, "\u2193", class: 'icon icon--arrow-down') +
            ' '.html_safe +
            view_context.content_tag(:span, 'Filter and sort', class: 'filters__link')
          }
        }
        buf << view_context.content_tag(:div, class: 'filters__dropdown filters__dropdown--hidden', data: { filters_target: 'dropdown' }) {
          render_filter_groups
        }
        buf
      })
    end
  end

  def render_filter_groups # rubocop:disable Metrics/MethodLength
    buf = ActiveSupport::SafeBuffer.new
    buf << view_context.content_tag(:div, class: 'filters__group') do
      render_radio('sort', 'time', @sort == 'time', 'Sort by date') +
        render_radio('sort', 'summary', @sort == 'summary', 'Sort by name')
    end
    buf << view_context.tag.hr
    buf << view_context.content_tag(:div, class: 'filters__group') do
      render_radio('period', 'day', @period == 'day', 'Daily view') +
        render_radio('period', 'week', @period == 'week', 'Weekly view') +
        render_radio('period', 'future', @period == 'future', 'Show all')
    end
    buf << view_context.tag.hr
    buf << view_context.content_tag(:div, class: 'filters__group') do
      render_radio('repeating', 'on', @repeating == 'on', 'Show repeats') +
        render_radio('repeating', 'last', @repeating == 'last', 'Show repeats last') +
        render_radio('repeating', 'off', @repeating == 'off', 'Hide repeats')
    end
    buf
  end

  def render_radio(name, value, checked, label_text)
    view_context.content_tag(:div, class: 'filters__option') do
      view_context.radio_button_tag(name, value, checked) +
        view_context.label_tag("#{name}_#{value}", label_text)
    end
  end

  def neighbourhoods
    return [] unless @site

    @neighbourhoods ||= EventsQuery.new(site: @site).neighbourhoods_with_counts(period: @period)
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
