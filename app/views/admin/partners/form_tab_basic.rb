# frozen_string_literal: true

class Views::Admin::Partners::FormTabBasic < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    div(class: 'grid grid-cols-1 lg:grid-cols-3 gap-6') do
      div(class: 'lg:col-span-2 space-y-4') do
        SectionHeader(
          title: t('admin.sections.basic_information'),
          description: t('admin.partners.sections.basic_info_description'),
          margin: 4
        )

        render_name_field
        render_summary_field
        render_description_field
        render_accessibility_field
      end

      ImageUpload(
        form:,
        attribute: :image,
        title: t('admin.partners.image.title'),
        aspect: ''
      )
    end
  end

  private

  def render_name_field
    Field(for: form.field_id(:name), label: "#{Partner.model_name.human} #{attr_label(:partner, :name)}", required: true) do |f|
      raw form.input_field(:name, class: 'input input-bordered w-full', **f.aria,
                                  'data-controller': 'partner-form-validation',
                                  'data-partner-form-validation-target': 'source',
                                  'data-action': 'input->partner-form-validation#checkInput',
                                  'data-validate-required': 'true',
                                  'data-validate-min': '5',
                                  'data-validate-required-message': t('admin.partners.validation.name_required'),
                                  'data-validate-min-message': t('admin.partners.validation.name_min_length'))
    end
  end

  def render_summary_field
    Field(for: form.field_id(:summary), label: attr_label(:partner, :summary),
          hint: t('admin.partners.fields.summary_hint'), counter: 200) do |f|
      raw form.input_field(:summary, as: :text, class: 'textarea textarea-bordered w-full min-h-16', maxlength: 200, **f.aria,
                                     data: { controller: 'auto-expand', char_counter_target: 'input',
                                             action: 'input->char-counter#update' })
    end
  end

  def render_description_field
    Field(for: form.field_id(:description), label: attr_label(:partner, :description),
          hint: t('admin.partners.fields.description_hint')) do |f|
      raw form.input_field(:description, class: 'textarea textarea-bordered w-full min-h-32', **f.aria,
                                         data: { controller: 'auto-expand' })
    end
  end

  def render_accessibility_field
    Field(for: form.field_id(:accessibility_info), label: attr_label(:partner, :accessibility_info),
          hint: t('admin.partners.fields.accessibility_hint')) do |f|
      raw form.input_field(:accessibility_info, class: 'textarea textarea-bordered w-full min-h-20', **f.aria,
                                                data: { controller: 'auto-expand' })
    end
  end
end
