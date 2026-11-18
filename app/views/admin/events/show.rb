# frozen_string_literal: true

class Views::Admin::Events::Show < Views::Admin::Base
  include Phlex::Rails::Helpers::TimeAgoInWords

  prop :event, Event, reader: :private
  prop :upcoming_siblings, Array, reader: :private
  prop :upcoming_siblings_count, Integer, reader: :private
  prop :siblings_count, Integer, reader: :private

  def view_template
    content_for(:title) { event.summary }

    div(class: 'space-y-6') do
      render_header
      render_details
      render_calendar
      render_partners
      render_siblings if event.calendar
    end
  end

  private

  def card(&)
    div(class: 'bg-white shadow-sm rounded-xl overflow-hidden border border-gray-200', &)
  end

  def card_heading(text)
    h2(class: 'px-6 py-4 border-b border-gray-200 text-lg font-semibold text-gray-900') { text }
  end

  def field_list(&)
    dl(class: 'px-6 py-4 grid grid-cols-1 sm:grid-cols-3 gap-x-6 gap-y-3 text-sm', &)
  end

  def field(key, &)
    dt(class: 'text-gray-600') { t("admin.events.show.fields.#{key}") }
    dd(class: 'sm:col-span-2 break-words', &)
  end

  def none
    span(class: 'text-gray-600 italic') { t('admin.events.show.none') }
  end

  def external_link(url)
    a(href: url, target: '_blank', rel: 'noopener', class: 'link link-hover text-placecal-orange-dark break-all') { url }
  end

  def timestamp(time)
    return none if time.blank?

    plain "#{I18n.l(time, format: :long)} (#{t('admin.time.ago', time: time_ago_in_words(time))})"
  end

  def render_header
    card do
      div(class: 'px-6 py-5 bg-gradient-to-r from-gray-50 to-white') do
        p(class: 'text-sm text-gray-600') { ::Event.model_name.human }
        h1(class: 'text-xl font-semibold text-gray-900 mt-1') { event.summary }
        p(class: 'mt-1 text-sm text-gray-600') do
          a(href: event.permalink, target: '_blank', rel: 'noopener', class: 'link link-hover') { t('admin.events.show.public_page') }
        end
      end
    end
  end

  def render_details
    card do
      card_heading(t('admin.events.show.details'))
      field_list do
        field(:dtstart) { I18n.l(event.dtstart, format: :long) }
        field(:dtend) { event.dtend ? I18n.l(event.dtend, format: :long) : none }
        field(:status) { t("admin.events.show.statuses.#{event.status}") }
        field(:uid) { event.uid.present? ? code(class: 'font-mono text-xs break-all') { event.uid } : none }
        field(:publisher_url) { event.publisher_url.present? ? external_link(event.publisher_url) : none }
        field(:repeats) { event.repeat_frequency || t('admin.events.show.does_not_repeat') }
        field(:created_at) { timestamp(event.created_at) }
        field(:updated_at) { timestamp(event.updated_at) }
      end
    end
  end

  def render_calendar
    calendar = event.calendar
    card do
      card_heading(t('admin.events.show.calendar'))
      if calendar.nil?
        p(class: 'px-6 py-4 text-sm text-gray-600') { t('admin.events.show.no_calendar') }
        next
      end

      field_list do
        field(:calendar_name) do
          link_to calendar.name, admin_calendar_path(calendar), class: 'font-medium link link-hover text-placecal-orange-dark'
        end
        field(:source) { external_link(calendar.source) }
        field(:importer) { importer_label(calendar) }
        field(:state) do
          state = calendar.calendar_state.to_s
          span(class: "badge badge-sm whitespace-nowrap #{CalendarDatatable::STATE_BADGES[state]}") { t("admin.jobs.states.#{state}") }
        end
        field(:last_import_at) { timestamp(calendar.last_import_at) }
      end
    end
  end

  def importer_label(calendar)
    mode = calendar.importer_mode.presence || 'auto'
    parser = CalendarImporter::CalendarImporter.parser_for_key(mode)
    return parser::NAME if parser

    used = CalendarImporter::CalendarImporter.parser_for_key(calendar.importer_used)
    used ? t('admin.events.show.auto_detected', importer: used::NAME) : t('admin.events.show.auto_detect')
  end

  def render_partners
    card do
      card_heading(t('admin.events.show.partners'))
      field_list do
        field(:organiser) { partner_link(event.organiser) }
        field(:place) { partner_link(event.place) }
      end
    end
  end

  def partner_link(partner)
    return none if partner.nil?

    link_to partner.name, edit_admin_partner_path(partner), class: 'font-medium link link-hover text-placecal-orange-dark'
  end

  def render_siblings
    card do
      div(class: 'px-6 py-4 border-b border-gray-200') do
        h2(class: 'text-lg font-semibold text-gray-900') { t('admin.events.show.siblings') }
        p(class: 'mt-1 text-sm text-gray-600') do
          t('admin.events.show.siblings_count', upcoming: upcoming_siblings_count, total: siblings_count)
        end
      end
      if upcoming_siblings.any?
        EventsTable(events: upcoming_siblings)
        p(class: 'px-6 py-3 text-sm text-gray-600') { t('admin.events.show.siblings_shown', count: upcoming_siblings.size) } if upcoming_siblings_count > upcoming_siblings.size
      else
        EmptyState(icon: :calendar, message: t('admin.events.show.no_upcoming_siblings'))
      end
    end
  end
end
