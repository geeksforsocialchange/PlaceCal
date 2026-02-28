# frozen_string_literal: true

class Components::Admin::OpeningTimes < Components::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder
  prop :partner, ::Partner

  def view_template
    div(data_controller: 'opening-times', data_opening_times_data_value: @partner.opening_times_data) do
      div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-6') do
        render_times_display
        render_add_form
      end
      safe(@form.text_area(:opening_times, data: { opening_times_target: 'textarea' }, hidden: true))
    end
  end

  private

  def render_times_display
    div(class: 'bg-base-200 rounded-lg p-4 min-h-40') do
      div(data_opening_times_target: 'list', class: 'space-y-2')
      p(
        data_opening_times_target: 'empty',
        class: "text-gray-600 italic text-center py-6 #{'hidden' if @partner.opening_times.present?}"
      ) { 'No opening times set yet' }
    end
  end

  def render_add_form
    div(class: 'space-y-3') do
      render_day_selector
      render_time_inputs
      render_all_day_checkbox
      button(
        data_action: 'click->opening-times#addOpeningTime',
        type: 'button',
        class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange w-full'
      ) { 'Add Opening Time' }
    end
  end

  def render_day_selector
    div(class: 'form-control') do
      label(class: 'label') do
        span(class: 'label-text font-medium') { t('admin.opening_times.day') }
      end
      select(class: 'select select-bordered w-full', data_opening_times_target: 'day') do
        ordered_day_names.each do |day_name|
          option(value: day_name) { day_name }
        end
      end
    end
  end

  def render_time_inputs
    div(class: 'grid grid-cols-2 gap-3') do
      div(class: 'form-control') do
        label(class: 'label') do
          span(class: 'label-text font-medium') { t('admin.opening_times.opens') }
        end
        input(class: 'input input-bordered w-full', type: 'time', value: '09:00',
              data_opening_times_target: 'open')
      end
      div(class: 'form-control') do
        label(class: 'label') do
          span(class: 'label-text font-medium') { t('admin.opening_times.closes') }
        end
        input(class: 'input input-bordered w-full', type: 'time', value: '17:00',
              data_opening_times_target: 'close')
      end
    end
  end

  def render_all_day_checkbox
    label(class: 'label cursor-pointer justify-start gap-3') do
      input(class: 'checkbox checkbox-warning', type: 'checkbox',
            data_opening_times_target: 'allDay',
            data_action: 'change->opening-times#allDay')
      span(class: 'label-text') { t('admin.opening_times.all_day') }
    end
  end

  def ordered_day_names
    day_names = I18n.t('date.day_names')
    [1, 2, 3, 4, 5, 6, 0].map { |i| day_names[i] }
  end
end
