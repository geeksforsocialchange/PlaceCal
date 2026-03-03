# frozen_string_literal: true

class Views::Admin::Sites::FormTabPreview < Views::Admin::Base
  include Phlex::Rails::Helpers::Truncate

  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    site = form.object

    h2(class: 'text-lg font-bold mb-1') { t('admin.sites.sections.preview_title') }
    p(class: 'text-sm text-gray-600 mb-6') { t('admin.sites.sections.preview_description') }

    render_partners_section(site)

    div(class: 'divider')

    render_events_section(site)
  end

  private

  def render_partners_section(site) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    site_partners = PartnersQuery.new(site: site).call

    div(class: 'mb-8') do
      h3(class: 'text-lg font-bold mb-1 flex items-center gap-2') do
        raw icon(:partnership, size: '5')
        plain Partner.model_name.human(count: 2)
        span(class: 'inline-flex items-center justify-center h-6 px-2 text-xs rounded-full font-bold bg-emerald-100 text-emerald-700') do
          plain site_partners.count.to_s
        end
      end
      p(class: 'text-sm text-gray-600 mb-4') { t('admin.sites.preview.partners_description') }

      if site_partners.any?
        render_partners_table(site_partners)
        if site_partners.count > 50
          p(class: 'text-sm text-gray-600 mt-2') do
            plain t('admin.sites.preview.showing_first', limit: 50, total: site_partners.count, items: Partner.model_name.human(count: 2).downcase)
          end
        end
      else
        render Components::Admin::EmptyState.new(
          icon: :partnership,
          message: t('admin.empty.no_items', items: Partner.model_name.human(count: 2).downcase)
        )
      end
    end
  end

  def render_partners_table(site_partners) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'overflow-x-auto') do
      table(class: 'table table-sm table-zebra') do
        thead do
          tr do
            th { Partner.model_name.human }
            th { Calendar.model_name.human(count: 2) }
            th { ::Event.model_name.human(count: 2) }
          end
        end
        tbody do
          site_partners.limit(50).each do |partner|
            render_partner_row(partner)
          end
        end
      end
    end
  end

  def render_partner_row(partner) # rubocop:disable Metrics/AbcSize
    tr do
      td do
        link_to(helpers.edit_admin_partner_path(partner), class: 'link link-hover text-placecal-orange font-medium') do
          plain partner.name
        end
        span(class: 'badge badge-error badge-xs ml-1') { t('admin.labels.hidden') } if partner.hidden
      end
      td { partner.calendars.count.to_s }
      td { partner.events.upcoming.count.to_s }
    end
  end

  def render_events_section(site) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    site_events = EventsQuery.new(site: site).scope.upcoming.where(dtstart: ..30.days.from_now).order(:dtstart)

    div do
      h3(class: 'text-lg font-bold mb-1 flex items-center gap-2') do
        raw icon(:calendar, size: '5')
        plain t('admin.sections.upcoming_events')
        span(class: 'inline-flex items-center justify-center h-6 px-2 text-xs rounded-full font-bold bg-sky-100 text-sky-700') do
          plain site_events.count.to_s
        end
      end
      p(class: 'text-sm text-gray-600 mb-4') { t('admin.sites.preview.events_description') }

      if site_events.any?
        render_events_table(site_events)
        if site_events.count > 30
          p(class: 'text-sm text-gray-600 mt-2') do
            plain t('admin.sites.preview.showing_first', limit: 30, total: site_events.count, items: ::Event.model_name.human(count: 2).downcase)
          end
        end
      else
        render Components::Admin::EmptyState.new(
          icon: :calendar,
          message: t('admin.time.no_upcoming_in_days', days: 30)
        )
      end
    end
  end

  def render_events_table(site_events) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'overflow-x-auto') do
      table(class: 'table table-sm table-zebra') do
        thead do
          tr do
            th { ::Event.model_name.human }
            th { t('admin.table.date_time') }
            th { Partner.model_name.human }
            th { Calendar.model_name.human }
          end
        end
        tbody do
          site_events.limit(30).each do |event|
            render_event_row(event)
          end
        end
      end
    end
  end

  def render_event_row(event) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    tr do
      td do
        div(class: 'font-medium') { truncate(event.summary, length: 40) }
      end
      td(class: 'whitespace-nowrap text-sm') do
        plain event.dtstart.strftime('%a %d %b %H:%M')
      end
      td do
        if event.partner
          link_to(truncate(event.partner.name, length: 25),
                  helpers.edit_admin_partner_path(event.partner),
                  class: 'link text-placecal-orange hover:text-orange-600 text-sm')
        end
      end
      td do
        if event.calendar
          link_to(truncate(event.calendar.name, length: 20),
                  helpers.edit_admin_calendar_path(event.calendar),
                  class: 'link text-placecal-orange hover:text-orange-600 text-sm')
        end
      end
    end
  end
end
