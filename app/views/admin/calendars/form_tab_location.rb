# frozen_string_literal: true

class Views::Admin::Calendars::FormTabLocation < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    render Components::Admin::SectionHeader.new(
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
      fieldset(class: 'fieldset bg-base-200/50 border border-base-300 rounded-box p-4') do
        legend(class: 'fieldset-legend') { t('admin.calendars.fields.default_location') }
        raw form.input_field(:place_id,
                             as: :select,
                             collection: options_for_location,
                             include_blank: t('admin.calendars.fields.default_location_blank'),
                             class: 'select select-bordered w-full bg-base-100',
                             data: { controller: 'tom-select' })
        p(class: 'fieldset-label mt-2') { t('admin.calendars.fields.default_location_hint') }
      end
    end
  end

  def render_strategy_column
    div(class: 'space-y-6') do
      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') { attr_label(:calendar, :strategy) }
        p(class: 'text-sm text-gray-600 mb-4') { t('admin.calendars.fields.strategy_hint') }
        render Components::Admin::RadioCardGroup.new(
          form: form,
          attribute: :strategy,
          values: Calendar.strategy.values,
          i18n_scope: 'admin.calendars.strategy'
        )
      end
    end
  end
end
