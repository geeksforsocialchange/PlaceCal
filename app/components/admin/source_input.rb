# frozen_string_literal: true

class Components::Admin::SourceInput < Components::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder
  prop :test_url, String
  prop :show_importer, _Boolean, default: true

  def view_template
    div(data_controller: 'source-validator', data_source_validator_test_url_value: @test_url) do
      render_source_field
      render_importer_field if @show_importer
    end
  end

  private

  def render_source_field
    fieldset(class: 'fieldset') do
      label(for: 'calendar_source', class: 'fieldset-legend') do
        plain I18n.t('activerecord.attributes.calendar.source')
        whitespace
        span(class: 'text-error') { I18n.t('admin.labels.required') }
      end
      div(class: 'flex gap-2') do
        safe(@form.input_field(:source,
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
      safe(@form.label(:importer_mode, I18n.t('admin.calendars.fields.calendar_type'), class: 'fieldset-legend'))
      safe(@form.input_field(:importer_mode,
                             as: :select,
                             collection: options_for_importer,
                             selected: @form.object.importer_mode || 'auto',
                             class: 'select select-bordered w-full',
                             data: { 'source-validator-target': 'importerModeSelect' }))
    end
  end
end
