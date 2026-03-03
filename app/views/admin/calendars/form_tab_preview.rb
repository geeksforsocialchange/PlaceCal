# frozen_string_literal: true

class Views::Admin::Calendars::FormTabPreview < Views::Admin::Base
  include Phlex::Rails::Helpers::Truncate

  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    calendar = form.object

    render_header(calendar)

    upcoming_events = calendar.events.where(dtstart: Time.current..).order(:dtstart).limit(50)
    past_events = calendar.events.where(dtstart: ...Time.current).order(dtstart: :desc).limit(20)

    if upcoming_events.any?
      render_upcoming_events(upcoming_events)
    else
      div(class: 'mb-8') do
        render Components::Admin::EmptyState.new(
          icon: :calendar,
          message: t('admin.empty.no_items', items: t('admin.sections.upcoming_events').downcase)
        )
      end
    end

    render_past_events(past_events) if past_events.any?
  end

  private

  def render_header(calendar) # rubocop:disable Metrics/AbcSize
    h2(class: 'text-lg font-bold mb-1 flex items-center gap-2') do
      raw icon(:event, size: '5')
      plain ::Event.model_name.human(count: 2)
      span(class: 'badge badge-neutral') { calendar.events.count.to_s }
    end
    p(class: 'text-sm text-gray-600 mb-6') { t('admin.calendars.sections.events_description') }
  end

  def render_upcoming_events(upcoming_events) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    h3(class: 'font-semibold mb-3 flex items-center gap-2') do
      span(class: 'text-success') { "\u25CF" }
      plain t('admin.sections.upcoming_events')
      span(class: 'badge badge-success badge-sm') { upcoming_events.count.to_s }
    end
    div(class: 'overflow-x-auto mb-8') do
      render_events_table(upcoming_events)
    end
  end

  def render_past_events(past_events) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'collapse collapse-arrow bg-base-200/50 border border-base-300 rounded-lg') do
      input(type: 'checkbox')
      div(class: 'collapse-title font-semibold flex items-center gap-2') do
        span(class: 'text-gray-600') { "\u25CF" }
        plain t('admin.calendars.events.past')
        span(class: 'badge badge-ghost badge-sm') { past_events.count.to_s }
      end
      div(class: 'collapse-content') do
        div(class: 'overflow-x-auto') do
          render_events_table(past_events, opacity: true)
        end
      end
    end
  end

  def render_events_table(events, opacity: false) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    table(class: 'table table-sm table-zebra') do
      thead do
        tr do
          th { ::Event.model_name.human }
          th { t('admin.table.date_time') }
          th { t('admin.table.location') }
        end
      end
      tbody do
        events.each do |event|
          render_event_row(event, opacity: opacity)
        end
      end
    end
  end

  def render_event_row(event, opacity: false) # rubocop:disable Metrics/AbcSize
    tr(class: opacity ? 'opacity-70' : nil) do
      td do
        div(class: 'font-medium') { truncate(event.summary, length: 60) }
      end
      td(class: 'whitespace-nowrap text-sm') do
        plain event.dtstart.strftime('%a %d %b %Y, %H:%M')
      end
      td(class: 'text-sm text-base-content/70') do
        render_event_location(event)
      end
    end
  end

  def render_event_location(event)
    if event.address
      plain truncate(event.address.to_s, length: 40)
    elsif event.partner
      plain event.partner.name
    else
      span(class: 'text-gray-500') { t('admin.calendars.events.no_location') }
    end
  end
end
