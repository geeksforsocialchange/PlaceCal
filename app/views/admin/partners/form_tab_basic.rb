# frozen_string_literal: true

class Views::Admin::Partners::FormTabBasic < Views::Admin::Base
  prop :form, _Any, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'grid grid-cols-1 lg:grid-cols-3 gap-6') do
      div(class: 'lg:col-span-2 space-y-4') do
        render Components::Admin::SectionHeader.new(
          title: t('admin.sections.basic_information'),
          description: t('admin.partners.sections.basic_info_description'),
          margin: 4
        )

        render_name_field
        render_summary_field
        render_description_field
        render_accessibility_field
      end

      render Components::Admin::ImageUpload.new(
        form: form,
        attribute: :image,
        title: t('admin.partners.image.title'),
        aspect: ''
      )
    end
  end

  private

  def render_name_field # rubocop:disable Metrics/MethodLength
    fieldset(class: 'fieldset') do
      raw form.label(:name, class: 'fieldset-legend') {
        "#{Partner.model_name.human} #{attr_label(:partner, :name)} " \
        "<span class=\"text-error\">#{t('admin.labels.required')}</span>".html_safe
      }
      raw form.input_field(:name, class: 'input input-bordered w-full',
                                  'data-controller': 'partner-form-validation',
                                  'data-partner-form-validation-target': 'source',
                                  'data-action': 'input->partner-form-validation#checkInput',
                                  'data-validate-required': 'true',
                                  'data-validate-min': '5',
                                  'data-validate-required-message': t('admin.partners.validation.name_required'),
                                  'data-validate-min-message': t('admin.partners.validation.name_min_length'))
    end
  end

  def render_summary_field # rubocop:disable Metrics/MethodLength
    fieldset(class: 'fieldset', data: { controller: 'char-counter', 'char-counter-max-value': '200' }) do
      raw form.label(:summary, attr_label(:partner, :summary), class: 'fieldset-legend')
      raw form.input_field(:summary, as: :text,
                                     class: 'textarea textarea-bordered w-full min-h-16',
                                     maxlength: 200,
                                     data: { controller: 'auto-expand', char_counter_target: 'input',
                                             action: 'input->char-counter#update' })
      div(class: 'flex items-center justify-between mt-1') do
        p(class: 'fieldset-label') { t('admin.partners.fields.summary_hint') }
        span(class: 'text-xs tabular-nums transition-colors', data: { char_counter_target: 'counter' }) { '0 / 200' }
      end
    end
  end

  def render_description_field
    fieldset(class: 'fieldset') do
      raw form.label(:description, attr_label(:partner, :description), class: 'fieldset-legend')
      raw form.input_field(:description, class: 'textarea textarea-bordered w-full min-h-32',
                                         data: { controller: 'auto-expand' })
      p(class: 'fieldset-label') { t('admin.partners.fields.description_hint') }
    end
  end

  def render_accessibility_field
    fieldset(class: 'fieldset') do
      raw form.label(:accessibility_info, attr_label(:partner, :accessibility_info), class: 'fieldset-legend')
      raw form.input_field(:accessibility_info, class: 'textarea textarea-bordered w-full min-h-20',
                                                data: { controller: 'auto-expand' })
      p(class: 'fieldset-label') { t('admin.partners.fields.accessibility_hint') }
    end
  end
end
