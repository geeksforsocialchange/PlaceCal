# frozen_string_literal: true

class Components::Admin::SourceInput < Components::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder
  prop :test_url, String
  prop :show_importer, _Boolean, default: true

  def view_template
    div(data_controller: 'source-validator',
        data_source_validator_test_url_value: @test_url,
        data_source_validator_api_token_parsers_value: api_token_modes.to_json) do
      render_source_field
      if @show_importer
        render_importer_field
        render_api_token_field
      end
    end
  end

  private

  def api_token_modes
    CalendarImporter::CalendarImporter::PARSERS.select(&:requires_api_token?).map { |p| p::KEY }
  end

  def render_source_field
    fieldset(class: 'fieldset') do
      label(for: 'calendar_source', class: 'fieldset-legend') do
        plain I18n.t('activerecord.attributes.calendar.source')
        whitespace
        span(class: 'text-error') { I18n.t('admin.labels.required') }
      end
      div(class: 'flex gap-2') do
        raw(@form.input_field(:source,
                              class: 'input input-bordered flex-1 font-mono text-sm',
                              placeholder: I18n.t('admin.calendars.fields.source_placeholder'),
                              autocomplete: 'off',
                              'data-source-validator-target': 'input',
                              'data-action': 'input->source-validator#sourceChanged'))
        render_test_button
      end
      p(class: 'fieldset-label') { safe(I18n.t('admin.calendars.handbook_hint_html')) }
      render_feedback
    end
  end

  def render_test_button
    button(
      type: 'button',
      class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange gap-2',
      data_source_validator_target: 'testButton',
      data_action: 'click->source-validator#testSource'
    ) do
      span(class: 'loading loading-spinner loading-sm hidden', data_source_validator_target: 'testSpinner')
      span(data_source_validator_target: 'testIconNeutral') { icon(:lightning, size: '5') }
      span(data_source_validator_target: 'testIconSuccess', class: 'hidden') { icon(:check_circle, size: '5') }
      span(data_source_validator_target: 'testIconError', class: 'hidden') { icon(:x_circle, size: '5') }
      span(data_source_validator_target: 'testButtonText') { I18n.t('admin.calendars.wizard.source.test_button') }
    end
  end

  def render_feedback
    div(class: 'mt-3 hidden', data_source_validator_target: 'feedback') do
      # Success
      div(class: 'alert alert-success text-sm hidden', data_source_validator_target: 'success') do
        icon(:check_circle, size: '5', css_class: 'shrink-0')
        div(class: 'flex-1') do
          p(class: 'font-semibold') { I18n.t('admin.calendars.wizard.source.success') }
          p(class: 'text-xs mt-1 hidden', data_source_validator_target: 'detectedFormat') do
            plain I18n.t('admin.calendars.wizard.source.detected_format')
            whitespace
            span(class: 'font-medium', data_source_validator_target: 'detectedFormatName')
          end
        end
      end

      # Error
      div(class: 'alert alert-error text-sm hidden', data_source_validator_target: 'error') do
        icon(:x_circle, size: '5', css_class: 'shrink-0')
        div do
          p(class: 'font-semibold') { I18n.t('admin.calendars.wizard.source.error') }
          p(class: 'text-xs mt-1', data_source_validator_target: 'errorMessage')
        end
      end
    end
  end

  def render_importer_field
    fieldset(class: 'fieldset mt-4') do
      raw(@form.label(:importer_mode, I18n.t('admin.calendars.fields.calendar_type'), class: 'fieldset-legend'))
      raw(@form.input_field(:importer_mode,
                            as: :select,
                            collection: options_for_importer,
                            selected: @form.object.importer_mode || 'auto',
                            class: 'select select-bordered w-full',
                            data: {
                              'source-validator-target': 'importerModeSelect',
                              action: 'change->source-validator#importerModeChanged'
                            }))
    end
  end

  # The API token field is only relevant for importers that authenticate with a key.
  # It is hidden server-side unless the saved mode needs one (or a token is already stored),
  # then shown/hidden by the source-validator controller as the mode changes.
  def render_api_token_field
    classes = %w[fieldset mt-4]
    classes << 'hidden' unless api_token_field_visible?

    fieldset(class: classes.join(' '), data: { 'source-validator-target': 'apiTokenSection' }) do
      label(for: 'calendar_api_token', class: 'fieldset-legend') do
        plain I18n.t('admin.calendars.fields.api_token')
        whitespace
        span(class: 'text-error') { I18n.t('admin.labels.required') }
      end
      raw(@form.input_field(:api_token,
                            type: :password,
                            class: 'input input-bordered w-full font-mono text-sm',
                            placeholder: I18n.t('admin.calendars.fields.api_token_placeholder'),
                            autocomplete: 'off',
                            value: @form.object.api_token,
                            'data-source-validator-target': 'apiTokenInput'))
      p(class: 'fieldset-label') { I18n.t('admin.calendars.fields.api_token_hint') }
    end
  end

  def api_token_field_visible?
    @form.object.importer_mode.in?(api_token_modes) || @form.object.api_token.present?
  end
end
