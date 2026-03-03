# frozen_string_literal: true

class Views::Admin::Calendars::New < Views::Admin::Base # rubocop:disable Metrics/ClassLength
  prop :calendar, Calendar, reader: :private
  prop :partner, _Nilable(Partner), reader: :private
  prop :partner_missing_address, _Boolean, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    content_for(:title) { 'New Calendar' }

    api_token_parsers = CalendarImporter::CalendarImporter::PARSERS
                        .select(&:requires_api_token?)
                        .map { |p| p::KEY }
                        .to_json

    div(data: {
          controller: 'calendar-wizard',
          'calendar-wizard-current-step-value': '1',
          'calendar-wizard-total-steps-value': '3',
          'calendar-wizard-test-url-value': helpers.test_source_admin_calendars_path,
          'calendar-wizard-api-token-parsers-value': api_token_parsers
        }) do
      div(class: 'max-w-4xl mx-auto') do
        render_header
        render_steps_indicator
      end

      simple_form_for calendar, url: helpers.admin_calendars_path, html: { data: { turbo: false } } do |form|
        div(class: 'max-w-4xl mx-auto') do
          render Components::Admin::Error.new(calendar)
          render_step_source(form)
          render_step_organiser(form)
          render_step_location(form)
        end

        render Components::Admin::SaveBar.new(
          wizard: true,
          wizard_controller: 'calendar-wizard',
          submit_label: t('admin.calendars.wizard.create_button'),
          continue_text_target: true
        )
      end
    end
  end

  private

  def render_header
    div(class: 'text-center mb-8') do
      h1(class: 'text-2xl font-bold text-base-content mb-2') { t('admin.calendars.wizard.title') }
      p(class: 'text-gray-600') { t('admin.calendars.wizard.subtitle') }
    end
  end

  def render_steps_indicator
    ul(class: 'steps steps-horizontal w-full mb-8') do
      [
        ['source', 1, true],
        ['organiser', 2, false],
        ['location', 3, false]
      ].each do |step_key, step_num, primary|
        li(class: "step#{' step-primary' if primary}",
           data: { 'calendar-wizard-target': 'stepIndicator', step: step_num.to_s }) do
          span(class: 'step-content') { t("admin.calendars.wizard.steps.#{step_key}") }
        end
      end
    end
  end

  def render_step_source(form) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'card bg-base-100 shadow-lg border border-base-300',
        data: { 'calendar-wizard-target': 'step', step: '1' }) do
      div(class: 'card-body') do
        render_step_header(:link, t('admin.calendars.wizard.source.title'),
                           t('admin.calendars.wizard.source.description'))
        div(class: 'space-y-6') do
          render_source_url_field(form)
          render_importer_mode_field(form)
          render_api_token_field(form)
          render_supported_sources
        end
      end
    end
  end

  def render_source_url_field(form) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    fieldset(class: 'fieldset bg-base-200/50 rounded-xl p-6') do
      legend(class: 'fieldset-legend text-base font-semibold') do
        plain attr_label(:calendar, :source)
        whitespace
        span(class: 'text-error') { t('admin.labels.required') }
      end
      div(class: 'flex gap-2') do
        raw form.input_field(:source,
                             class: 'input input-bordered input-lg flex-1 font-mono text-sm',
                             placeholder: t('admin.calendars.fields.source_placeholder'),
                             autocomplete: 'off',
                             'data-calendar-wizard-target': 'sourceInput',
                             'data-action': 'input->calendar-wizard#sourceChanged')
        button(type: 'button',
               class: 'btn btn-lg bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange gap-2',
               data: { 'calendar-wizard-target': 'testButton', action: 'click->calendar-wizard#testSource' }) do
          span(class: 'loading loading-spinner loading-sm hidden', data: { 'calendar-wizard-target': 'testSpinner' })
          span(data: { 'calendar-wizard-target': 'testIconNeutral' }) { raw icon(:lightning, size: '5') }
          span(data: { 'calendar-wizard-target': 'testIconSuccess' }, class: 'hidden') { raw icon(:check_circle, size: '5') }
          span(data: { 'calendar-wizard-target': 'testIconError' }, class: 'hidden') { raw icon(:x_circle, size: '5') }
          span(data: { 'calendar-wizard-target': 'testButtonText' }) { t('admin.calendars.wizard.source.test_button') }
        end
      end
      p(class: 'text-sm text-gray-600 mt-2') { raw safe(t('admin.calendars.handbook_hint_html')) }
      render_source_feedback
    end
  end

  def render_source_feedback # rubocop:disable Metrics/MethodLength
    div(class: 'mt-2 hidden', data: { 'calendar-wizard-target': 'sourceFeedback' }) do
      div(class: 'alert alert-success text-sm hidden', data: { 'calendar-wizard-target': 'sourceSuccess' }) do
        raw icon(:check_circle, size: '5', css_class: 'shrink-0')
        div(class: 'flex-1') do
          p(class: 'font-semibold') { t('admin.calendars.wizard.source.success') }
          p(class: 'text-xs mt-1 hidden', data: { 'calendar-wizard-target': 'detectedFormat' }) do
            plain t('admin.calendars.wizard.source.detected_format')
            whitespace
            span(class: 'font-medium', data: { 'calendar-wizard-target': 'detectedFormatName' })
          end
        end
      end
      div(class: 'alert alert-error text-sm hidden', data: { 'calendar-wizard-target': 'sourceError' }) do
        raw icon(:x_circle, size: '5', css_class: 'shrink-0')
        div do
          p(class: 'font-semibold') { t('admin.calendars.wizard.source.error') }
          p(class: 'text-xs mt-1', data: { 'calendar-wizard-target': 'sourceErrorMessage' })
        end
      end
    end
  end

  def render_importer_mode_field(form)
    fieldset(class: 'fieldset bg-base-200/50 rounded-xl px-6 pb-6 pt-2 hidden !mt-0',
             data: { 'calendar-wizard-target': 'importerModeSection' }) do
      legend(class: 'fieldset-legend text-base font-semibold') { t('admin.calendars.fields.calendar_type') }
      raw form.input_field(:importer_mode,
                           as: :select,
                           collection: options_for_importer,
                           selected: 'auto',
                           class: 'select select-bordered w-full',
                           data: { 'calendar-wizard-target': 'importerModeSelect', action: 'change->calendar-wizard#importerModeChanged' })
      p(class: 'text-sm text-gray-600 mt-2') { t('admin.calendars.wizard.source.importer_hint') }
    end
  end

  def render_api_token_field(form)
    fieldset(class: 'fieldset bg-base-200/50 rounded-xl px-6 pb-6 pt-2 hidden !mt-0',
             data: { 'calendar-wizard-target': 'apiTokenSection' }) do
      legend(class: 'fieldset-legend text-base font-semibold') do
        plain t('admin.calendars.fields.api_token')
        whitespace
        span(class: 'text-error') { t('admin.labels.required') }
      end
      raw form.input_field(:api_token,
                           type: :password,
                           class: 'input input-bordered w-full font-mono text-sm',
                           placeholder: t('admin.calendars.fields.api_token_placeholder'),
                           autocomplete: 'off',
                           'data-calendar-wizard-target': 'apiTokenInput',
                           'data-action': 'input->calendar-wizard#apiTokenChanged')
      p(class: 'text-sm text-gray-600 mt-2') { t('admin.calendars.fields.api_token_hint') }
    end
  end

  def render_supported_sources
    details(class: 'collapse collapse-arrow bg-base-200/50 border border-base-300 rounded-box') do
      summary(class: 'collapse-title text-sm font-medium') do
        raw icon(:info, size: '4', css_class: 'inline mr-2 text-gray-600')
        plain t('admin.calendars.sections.supported_sources')
      end
      div(class: 'collapse-content') do
        ul(class: 'text-xs text-base-content/70 space-y-1 pt-2') do
          helpers.calendar_import_sources do |name, domains|
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
      end
    end
  end

  def render_step_organiser(form) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'card bg-base-100 shadow-lg border border-base-300 hidden',
        data: { 'calendar-wizard-target': 'step', step: '2' }) do
      div(class: 'card-body') do
        render_step_header(:partner, t('admin.calendars.wizard.organiser.title'),
                           t('admin.calendars.wizard.organiser.description'))
        div(class: 'space-y-6') do
          fieldset(class: 'fieldset bg-base-200/50 rounded-xl p-6') do
            legend(class: 'fieldset-legend text-base font-semibold') do
              plain t('admin.calendars.fields.partner_organiser')
              whitespace
              span(class: 'text-error') { t('admin.labels.required') }
            end
            raw form.input_field(:partner_id,
                                 as: :select,
                                 collection: options_for_organiser,
                                 include_blank: t('admin.placeholders.select_model', model: Partner.model_name.human.downcase),
                                 selected: partner&.id.to_s,
                                 class: 'select select-bordered w-full',
                                 data: { controller: 'tom-select', 'calendar-wizard-target': 'partnerSelect',
                                         action: 'change->calendar-wizard#partnerChanged' })
            p(class: 'text-sm text-gray-600 mt-2') { t('admin.calendars.fields.partner_hint') }
          end
          fieldset(class: 'fieldset bg-base-200/50 rounded-xl p-6') do
            legend(class: 'fieldset-legend text-base font-semibold') do
              plain t('admin.calendars.fields.calendar_name')
              whitespace
              span(class: 'text-error') { t('admin.labels.required') }
            end
            raw form.input_field(:name,
                                 class: 'input input-bordered w-full',
                                 placeholder: t('admin.calendars.wizard.organiser.name_placeholder'),
                                 'data-calendar-wizard-target': 'nameInput',
                                 'data-action': 'input->calendar-wizard#nameChanged')
            p(class: 'text-sm text-gray-600 mt-2') { t('admin.calendars.fields.name_hint') }
          end
        end
      end
    end
  end

  def render_step_location(form) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'card bg-base-100 shadow-lg border border-base-300 hidden',
        data: { 'calendar-wizard-target': 'step', step: '3' }) do
      div(class: 'card-body') do
        render_step_header(:map_pin, t('admin.calendars.wizard.location.title'),
                           t('admin.calendars.wizard.location.description'))
        div(class: 'space-y-6') do
          fieldset(class: 'fieldset bg-base-200/50 rounded-xl p-6') do
            legend(class: 'fieldset-legend text-base font-semibold') { attr_label(:calendar, :strategy) }
            render Components::Admin::RadioCardGroup.new(
              form: form, attribute: :strategy,
              values: Calendar.strategy.values, i18n_scope: 'admin.calendars.strategy'
            )
            p(class: 'text-sm text-gray-600 mt-2') { t('admin.calendars.wizard.location.strategy_hint') }
          end
          fieldset(class: 'fieldset bg-base-200/50 rounded-xl p-6') do
            legend(class: 'fieldset-legend text-base font-semibold') { t('admin.calendars.fields.default_location') }
            if partner_missing_address
              div(class: 'alert alert-warning mb-4') do
                raw icon(:warning, size: '5', css_class: 'shrink-0')
                span { t('admin.calendars.wizard.location.partner_no_address', partner: partner.name) }
              end
            end
            raw form.input_field(:place_id,
                                 as: :select,
                                 collection: options_for_location,
                                 include_blank: t('admin.calendars.fields.default_location_blank'),
                                 class: 'select select-bordered w-full',
                                 data: { controller: 'tom-select', 'calendar-wizard-target': 'placeSelect' })
            p(class: 'text-sm text-gray-600 mt-2') { t('admin.calendars.wizard.location.default_hint') }
          end
        end
      end
    end
  end

  def render_step_header(icon_name, title, description)
    div(class: 'flex items-start gap-4 mb-6') do
      div(class: 'shrink-0 w-12 h-12 rounded-xl bg-placecal-orange/10 flex items-center justify-center') do
        raw icon(icon_name, size: '6', css_class: 'text-placecal-orange')
      end
      div do
        h2(class: 'card-title text-xl') { title }
        p(class: 'text-gray-600 text-sm mt-1') { description }
      end
    end
  end
end
