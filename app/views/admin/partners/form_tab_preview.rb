# frozen_string_literal: true

class Views::Admin::Partners::FormTabPreview < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    partner = form.object

    SectionHeader(
      title: t('admin.partners.sections.live_preview'),
      description: t('admin.partners.sections.preview_description')
    )

    render_browser_mockup(partner)

    div(class: 'divider my-8')

    render_upcoming_events(partner)
  end

  private

  def render_browser_mockup(partner) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'mockup-browser bg-base-300 border border-base-300 max-w-4xl') do
      div(class: 'mockup-browser-toolbar') do
        div(class: 'input text-sm') { "placecal.org/partners/#{partner.slug}" }
      end
      div(class: 'bg-base-100') do
        render_partner_header(partner)
        div(class: 'p-6') do
          div(class: 'grid grid-cols-1 lg:grid-cols-3 gap-8') do
            div(class: 'lg:col-span-2') do
              render_description(partner)
              render_accessibility(partner)
            end
            div(class: 'space-y-4') do
              render_image(partner)
              render_sidebar_details(partner)
            end
          end
        end
      end
    end
  end

  def render_partner_header(partner)
    div(class: 'bg-neutral text-neutral-content p-6') do
      h1(class: 'text-2xl font-bold') { partner.name }
      p(class: 'mt-2 text-neutral-content/80') { partner.summary } if partner.summary.present?
    end
  end

  def render_description(partner)
    if partner.description_html.present?
      div(class: 'prose prose-sm max-w-none') do
        raw safe(partner.description_html.to_s)
      end
    else
      p(class: 'text-gray-600 italic') { t('admin.partners.preview.no_description') }
    end
  end

  def render_accessibility(partner)
    return if partner.accessibility_info.blank?

    div(class: 'mt-6') do
      h3(class: 'font-semibold mb-2') { t('admin.sections.accessibility') }
      p(class: 'text-sm') { partner.accessibility_info }
    end
  end

  def render_image(partner)
    if partner.image.present?
      image_tag partner.image.standard.url, class: 'rounded-box w-full'
    else
      div(class: 'bg-base-200 rounded-box aspect-square flex items-center justify-center') do
        span(class: 'text-gray-400 text-sm') { t('admin.images.no_image') }
      end
    end
  end

  def render_sidebar_details(partner) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'card bg-base-200 card-body p-4 text-sm') do
      if partner.address&.to_s.present?
        div(class: 'mb-3') do
          div(class: 'font-semibold text-xs uppercase text-gray-600 mb-1') { attr_label(:partner, :address) }
          p { partner.address.to_s }
        end
      end

      if partner.url.present?
        div(class: 'mb-3') do
          div(class: 'font-semibold text-xs uppercase text-gray-600 mb-1') { attr_label(:partner, :website) }
          link_to partner.url, partner.url,
                  target: '_blank', class: 'link text-placecal-orange hover:text-orange-600 break-all', rel: 'noopener'
        end
      end

      if partner.public_email.present?
        div(class: 'mb-3') do
          div(class: 'font-semibold text-xs uppercase text-gray-600 mb-1') { attr_label(:partner, :email) }
          mail_to partner.public_email, partner.public_email,
                  class: 'link text-placecal-orange hover:text-orange-600'
        end
      end

      if partner.public_phone.present? # rubocop:disable Style/GuardClause
        div do
          div(class: 'font-semibold text-xs uppercase text-gray-600 mb-1') { attr_label(:partner, :phone) }
          p { partner.public_phone }
        end
      end
    end
  end

  def render_upcoming_events(partner) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    SectionHeader(
      title: t('admin.sections.upcoming_events'),
      description: t('admin.partners.sections.upcoming_events_description'),
      tag: :h3
    )

    upcoming_events = partner.events.upcoming.where(dtstart: ..30.days.from_now).order(:dtstart).limit(20)

    if upcoming_events.any?
      render_events_table(upcoming_events)
    else
      EmptyState(icon: :calendar, message: t('admin.time.no_upcoming_in_days', days: 30))
    end
  end

  def render_events_table(events) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'overflow-x-auto') do
      table(class: 'table table-sm table-zebra') do
        thead do
          tr do
            th { ::Event.model_name.human }
            th { t('admin.table.date_time') }
            th { Calendar.model_name.human }
          end
        end
        tbody do
          events.each do |event|
            tr do
              td do
                div(class: 'font-medium') { helpers.truncate(event.summary, length: 50) }
              end
              td(class: 'whitespace-nowrap text-sm') do
                plain event.dtstart.strftime('%a %d %b %H:%M')
              end
              td do
                if event.calendar
                  link_to event.calendar.name, helpers.edit_admin_calendar_path(event.calendar),
                          class: 'link text-placecal-orange hover:text-orange-600 text-sm'
                end
              end
            end
          end
        end
      end
    end
  end
end
