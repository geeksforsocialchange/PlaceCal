# frozen_string_literal: true

class Views::Admin::Calendars::FormTabSource < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    calendar = form.object

    SectionHeader(
      title: t('admin.calendars.tabs.source'),
      description: t('admin.calendars.sections.source_description')
    ) do |c|
      c.with_icon { raw icon(:calendar, size: '5') }
    end

    div(class: 'grid grid-cols-1 lg:grid-cols-3 gap-8') do
      render_left_column(calendar)
      render_right_column(calendar)
    end
  end

  private

  def render_left_column(calendar)
    div(class: 'lg:col-span-2 space-y-4', data: { controller: 'calendar-name-suggest' }) do
      render_partner_field(calendar)

      SourceInput(
        form: form,
        test_url: test_source_admin_calendars_path
      )

      render_name_field
    end
  end

  def render_partner_field(calendar)
    fieldset(class: 'fieldset') do
      label(for: 'calendar_organiser_id', class: 'fieldset-legend') do
        plain t('admin.calendars.fields.partner_organiser')
        whitespace
        span(class: 'text-error') { t('admin.labels.required') }
      end
      raw form.input_field(:organiser_id,
                           as: :select,
                           collection: options_for_organiser,
                           include_blank: t('admin.placeholders.select_model', model: Partner.model_name.human.downcase),
                           selected: (calendar.organiser&.id || calendar.organiser_id).to_s,
                           class: 'select select-bordered w-full',
                           'aria-label': t('admin.calendars.fields.partner_organiser'),
                           data: {
                             controller: 'tom-select',
                             'calendar-name-suggest-target': 'partner',
                             action: 'change->calendar-name-suggest#partnerChanged'
                           })
      p(class: 'fieldset-label') { t('admin.calendars.fields.partner_hint') }
    end
  end

  def render_name_field
    fieldset(class: 'fieldset') do
      label(for: 'calendar_name', class: 'fieldset-legend') do
        plain t('admin.calendars.fields.calendar_name')
        whitespace
        span(class: 'text-error') { t('admin.labels.required') }
      end
      raw form.input_field(:name,
                           class: 'input input-bordered w-full',
                           data: { 'calendar-name-suggest-target': 'name' })
      p(class: 'fieldset-label') do
        span(data: { 'calendar-name-suggest-target': 'suggestion' }, class: 'hidden') do
          button(type: 'button',
                 class: 'link text-placecal-orange-dark text-xs',
                 data: { action: 'calendar-name-suggest#applySuggestion' }) do
            plain t('admin.calendars.fields.apply_suggestion')
          end
        end
        span { t('admin.calendars.fields.name_hint') }
      end
    end
  end

  def render_right_column(calendar)
    div do
      FormCard(icon: :info, title: t('admin.calendars.sections.supported_sources')) do
        ul(class: 'text-xs text-base-content/70 space-y-1') do
          calendar_import_sources do |name, domains|
            li(class: 'flex items-start gap-2') do
              span(class: 'text-placecal-orange') { "\u2022" }
              span do
                strong { name }
                whitespace
                span(class: 'text-gray-600') { "(#{domains.join(', ')})" }
              end
            end
          end
        end
        if calendar.importer_used.present?
          p(class: 'text-xs text-gray-600 mt-3 pt-3 border-t border-base-300') do
            plain t('admin.calendars.sections.last_imported_using', importer: calendar.importer_used)
          end
        end
      end
    end
  end
end
