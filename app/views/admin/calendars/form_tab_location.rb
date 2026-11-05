# frozen_string_literal: true

class Views::Admin::Calendars::FormTabLocation < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    SectionHeader(
      title: t('admin.calendars.tabs.location'),
      description: t('admin.calendars.sections.location_description')
    ) do |c|
      c.with_icon { raw icon(:map_pin, size: '5') }
    end

    div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-8') do
      render_location_column
      render_strategy_column
    end
  end

  private

  def render_location_column
    div(class: 'space-y-6') do
      Field(for: form.field_id(:place_id), label: t('admin.calendars.fields.default_location'),
            hint: t('admin.calendars.fields.default_location_hint'), class: 'bg-base-200/50 border border-base-300 rounded-box p-4') do |f|
        raw form.input_field(:place_id, **f.aria,
                             as: :select,
                             collection: options_for_location,
                             include_blank: t('admin.calendars.fields.default_location_blank'),
                             class: 'select select-bordered w-full bg-base-100',
                             aria: { label: t('admin.calendars.fields.default_location') },
                             data: { controller: 'tom-select' })
      end
    end
  end

  def render_strategy_column
    div(class: 'space-y-6') do
      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') { attr_label(:calendar, :strategy) }
        p(class: 'text-sm text-gray-600 mb-4') { t('admin.calendars.fields.strategy_hint') }
        RadioCardGroup(
          form:,
          attribute: :strategy,
          values: Calendar.strategy.values,
          i18n_scope: 'admin.calendars.strategy'
        )
      end
    end
  end
end
