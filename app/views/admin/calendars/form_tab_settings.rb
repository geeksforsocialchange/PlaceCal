# frozen_string_literal: true

class Views::Admin::Calendars::FormTabSettings < Views::Admin::Base
  prop :form, _Any, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    calendar = form.object

    render_api_token_section(calendar)

    render Components::Admin::DangerZone.new(
      title: t('admin.actions.delete_model', model: Calendar.model_name.human.downcase),
      description: t('admin.calendars.danger_zone.delete_description', count: calendar.events.count),
      button_text: t('admin.actions.delete_model', model: Calendar.model_name.human),
      button_path: helpers.admin_calendar_path(calendar),
      confirm: t('admin.confirm.delete_with_count',
                 model: Calendar.model_name.human.downcase,
                 count: calendar.events.count,
                 items: ::Event.model_name.human(count: 2).downcase)
    )
  end

  private

  def render_api_token_section(calendar) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    api_token_modes = CalendarImporter::CalendarImporter::PARSERS.select(&:requires_api_token?).map { |p| p::KEY }
    return unless calendar.importer_mode.in?(api_token_modes) || calendar.api_token.present?

    render Components::Admin::SectionHeader.new(
      title: t('admin.calendars.fields.api_token'),
      description: t('admin.calendars.fields.api_token_hint')
    ) do |c|
      c.with_icon { raw icon(:key, size: '5') }
    end

    div(class: 'max-w-xl') do
      fieldset(class: 'fieldset') do
        label(for: 'calendar_api_token', class: 'fieldset-legend') do
          plain t('admin.calendars.fields.api_token')
        end
        raw form.input_field(:api_token,
                             type: :password,
                             class: 'input input-bordered w-full font-mono text-sm',
                             placeholder: t('admin.calendars.fields.api_token_placeholder'),
                             autocomplete: 'off',
                             value: calendar.api_token)
        p(class: 'fieldset-label') { t('admin.calendars.fields.api_token_hint') }
      end
    end
  end
end
