# frozen_string_literal: true

class Components::Admin::RadioFilterGroup < Components::Admin::Base
  prop :group_label, String
  prop :filters, _Any
  prop :show_all, _Boolean, default: true

  def view_template
    fieldset(class: 'relative flex items-center gap-2 pl-3 pr-3 py-1 border border-gray-300 rounded-lg bg-white/50') do
      span(class: 'text-xs font-medium text-gray-500') { @group_label }
      @filters.each_with_index do |filter, idx|
        is_last = idx == @filters.length - 1
        div(
          class: 'flex items-center gap-2',
          data_admin_table_target: 'radioFilter',
          data_filter_column: filter[:column]
        ) do
          span(class: 'text-xs font-medium text-gray-600') { filter[:label] }
          div(class: 'inline-flex rounded-md bg-gray-100 p-0.5') do
            if @show_all
              button(
                type: 'button',
                data_action: 'click->admin-table#applyRadioFilter',
                data_filter_value: '',
                data_is_all: 'true',
                class: 'filter-btn filter-btn-all px-2 py-0.5 text-xs font-medium rounded transition-all duration-150 bg-white text-gray-900 shadow-sm'
              ) { t('admin.labels.all') }
            end
            filter[:options]&.each do |opt|
              button(
                type: 'button',
                data_action: 'click->admin-table#applyRadioFilter',
                data_filter_value: opt[:value],
                class: 'filter-btn px-2 py-0.5 text-xs font-medium rounded transition-all duration-150 text-gray-600 hover:text-gray-900'
              ) { opt[:label] }
            end
          end
        end
        span(class: 'text-gray-300 text-xs') { '|' } unless is_last
      end
    end
  end
end
