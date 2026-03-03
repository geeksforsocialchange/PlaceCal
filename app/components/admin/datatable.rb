# frozen_string_literal: true

class Components::Admin::Datatable < Components::Admin::Base # rubocop:disable Metrics/ClassLength
  register_value_helper :icon_column_header

  prop :title, String
  prop :model, Symbol
  prop :column_titles, _Array(String)
  prop :columns, _Array(Symbol)
  prop :column_config, _Any, default: -> { {} }
  prop :default_sort, _Any, default: -> { {} }
  prop :filters, _Any, default: -> { [] }
  prop :secondary_filters, _Any, default: -> { [] }
  prop :data, _Any
  prop :source, String
  prop :new_link, _Nilable(String), default: nil
  prop :search_fieldset, _Boolean, default: false

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    content_for(:title) { @title }
    model_name = @model.to_s.chop.humanize

    div(
      class: 'bg-white shadow-sm rounded-xl overflow-hidden border border-gray-200',
      data_controller: 'admin-table',
      data_admin_table_source_value: @source,
      data_admin_table_columns_value: columns_json,
      data_admin_table_page_length_value: '25',
      data_admin_table_default_sort_column_value: @default_sort[:column] || '',
      data_admin_table_default_sort_direction_value: @default_sort[:direction] || 'asc'
    ) do
      render_header(model_name)
      render_filter_bar
      render_table
      render_footer
    end
  end

  private

  def columns_json
    @columns.map do |c|
      {
        data: c.to_s,
        hidden: @column_config.dig(c, :hidden) || false,
        align: @column_config.dig(c, :align)&.to_s
      }
    end.to_json
  end

  def render_header(model_name) # rubocop:disable Metrics/AbcSize
    div(class: 'px-6 py-5 border-b border-gray-200 bg-gradient-to-r from-gray-50 to-white') do
      div(class: 'flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4') do
        div do
          h1(class: 'text-xl font-semibold text-gray-900') { @title }
          p(class: 'mt-1 text-sm text-gray-500', data_admin_table_target: 'summary') { t('admin.labels.loading') }
        end
        render_new_link(model_name) if @new_link
      end
    end
  end

  def render_new_link(model_name)
    link_to(@new_link, data: { turbo: false },
                       class: 'inline-flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg ' \
                              'text-white bg-orange-700 hover:bg-orange-800 transition-colors shadow-sm') do
      icon(:plus, size: '4')
      plain t('admin.actions.add_model', model: model_name)
    end
  end

  def render_filter_bar # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    has_radio = @filters.any? { |f| f[:type] == :radio }
    has_dropdown = @filters.any? { |f| f[:type] != :radio }
    radio_filters = @filters.select { |f| f[:type] == :radio }

    div(class: 'px-6 py-4 bg-gray-50 border-b border-gray-200') do
      div(class: 'flex flex-wrap items-center gap-3') do
        render_search_input
        render_radio_filters(radio_filters) if has_radio
        render_dropdown_filters(@filters) if has_dropdown
        render_clear_buttons
      end
      render_secondary_filters if @secondary_filters.any?
    end
  end

  def render_search_input # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    if @search_fieldset
      fieldset(class: 'relative flex items-center px-3 py-2 pt-3 border border-gray-300 rounded-lg bg-gray-100') do
        legend(class: 'font-medium text-gray-400 uppercase tracking-wider px-1 ml-1 bg-gray-50',
               style: 'font-size: 9px; line-height: 1;') { t('admin.datatable.search') }
        div(class: 'flex items-center gap-2') do
          icon(:search, size: '3.5', css_class: 'text-gray-400 shrink-0')
          input(type: 'search',
                class: 'w-44 bg-transparent text-xs text-gray-700 placeholder-gray-400 focus:outline-none',
                placeholder: t('admin.placeholders.type_to_filter'),
                data_admin_table_target: 'search',
                data_action: 'input->admin-table#search')
        end
      end
    else
      div(class: 'relative') do
        div(class: 'absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none') do
          icon(:search, size: '4', css_class: 'text-gray-400')
        end
        input(type: 'search',
              class: 'block w-56 pl-10 pr-3 py-2 border border-gray-300 rounded-lg text-xs placeholder-gray-400 ' \
                     'focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-transparent',
              placeholder: t('admin.placeholders.search'),
              data_admin_table_target: 'search',
              data_action: 'input->admin-table#search')
      end
    end
  end

  def render_radio_filters(radio_filters)
    ungrouped = radio_filters.reject { |f| f[:group] }
    grouped = radio_filters.select { |f| f[:group] }.group_by { |f| f[:group] }

    ungrouped.each do |filter|
      render Components::Admin::RadioFilter.new(
        column: filter[:column], label: filter[:label], options: filter[:options] || []
      )
    end

    grouped.each do |group_name, group_filters|
      render Components::Admin::RadioFilterGroup.new(
        group_label: group_name, filters: group_filters
      )
    end
  end

  def render_dropdown_filters(all_filters) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    all_filters.each do |filter|
      next if filter[:type] == :radio

      if filter[:tom_select]
        render_tom_select_filter(filter)
      else
        render_select_filter(filter)
      end
    end
  end

  def render_tom_select_filter(filter) # rubocop:disable Metrics/AbcSize
    div(class: "ts-filter #{filter[:width]}") do
      select(data_controller: 'tom-select',
             data_admin_table_target: 'filter',
             data_filter_column: filter[:column],
             aria_label: filter[:label],
             data_action: 'change->admin-table#applyFilter') do
        option(value: '') { filter[:label] }
        filter[:options]&.each do |opt|
          option(value: opt[:value]) { opt[:label] }
        end
      end
    end
  end

  def render_select_filter(filter) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    is_hierarchical = filter[:type] == :hierarchical
    is_dependent = filter[:depends_on].present? || filter[:parent_filter].present?
    target_name = if is_hierarchical
                    'hierarchicalFilter'
                  elsif is_dependent
                    'dependentFilter'
                  else
                    'filter'
                  end

    attrs = build_select_attrs(filter, target_name, is_hierarchical, is_dependent)

    select(**attrs) do
      option(value: '') { filter[:label] }
      filter[:options]&.each do |opt|
        opt_attrs = { value: opt[:value] }
        opt_attrs[:data_parent] = opt[:parent] if opt[:parent]
        opt_attrs[:selected] = true if filter[:default].present? && filter[:default].to_s == opt[:value].to_s
        option(**opt_attrs) { opt[:label] }
      end
    end
  end

  def build_select_attrs(filter, target_name, is_hierarchical, is_dependent) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    css = +'select-filter'
    css << ' hidden' if is_dependent
    css << " #{filter[:width]}" if filter[:width]

    attrs = {
      data_admin_table_target: target_name,
      data_filter_column: filter[:column],
      aria_label: filter[:label],
      data_action: 'change->admin-table#applyFilter',
      class: css
    }
    attrs[:data_filter_parent] = filter[:parent_filter] if filter[:parent_filter]
    attrs[:data_filter_depends_on] = filter[:depends_on] if filter[:depends_on]
    attrs[:data_filter_default] = filter[:default] if filter[:default].present?
    attrs[:data_filter_level] = filter[:level] if is_hierarchical
    attrs[:data_filter_endpoint] = filter[:endpoint] if filter[:endpoint]
    attrs
  end

  def render_clear_buttons # rubocop:disable Metrics/MethodLength
    if @filters.any? || @secondary_filters.any?
      button(type: 'button',
             data_action: 'click->admin-table#clearFilters',
             data_admin_table_target: 'clearFilters',
             style: 'display: none;',
             class: 'btn-clear-filters') do
        icon(:x, size: '3.5')
        plain t('admin.datatable.clear_filters')
      end
    end
    button(type: 'button',
           data_action: 'click->admin-table#resetSort',
           data_admin_table_target: 'clearSort',
           style: 'display: none;',
           class: 'btn-clear-filters') do
      icon(:x, size: '3.5')
      plain t('admin.datatable.reset_sort')
    end
  end

  def render_secondary_filters # rubocop:disable Metrics/AbcSize
    div(class: 'flex flex-wrap items-center gap-3 mt-3') do
      @secondary_filters.each do |filter|
        if filter[:type] == :radio
          render Components::Admin::RadioFilter.new(
            column: filter[:column], label: filter[:label], options: filter[:options] || []
          )
        else
          render_select_filter(filter)
        end
      end
    end
  end

  def render_table # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'overflow-x-auto') do
      table(class: 'min-w-full', data_admin_table_target: 'table') do
        thead do
          tr(class: 'bg-gray-50 border-b border-gray-200') do
            @column_titles.each_with_index do |col_title, index|
              render_column_header(col_title, index)
            end
          end
        end
        tbody(class: 'divide-y divide-gray-100', data_admin_table_target: 'tbody') do
          render_loading_row
        end
      end
    end
  end

  def render_column_header(col_title, index) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    col_config = @column_config[@columns[index]]
    return if col_config&.dig(:hidden)

    sortable = col_config.nil? || col_config[:sortable] != false
    fit_content = col_config&.dig(:fit)
    width_class = fit_content ? 'w-px whitespace-nowrap' : (col_config&.dig(:width) || '')
    align_class = col_config&.dig(:align) == :center ? 'text-center' : 'text-left'
    sort_default_dir = col_config&.dig(:sort_default)

    attrs = { data_column: @columns[index],
              class: "px-4 py-3 #{align_class} text-xs font-semibold text-gray-600 uppercase tracking-wider " \
                     "#{width_class} #{'cursor-pointer hover:bg-gray-100 select-none' if sortable}" }
    attrs[:data_action] = 'click->admin-table#sort' if sortable
    attrs[:data_sort_default] = sort_default_dir if sort_default_dir

    th(**attrs) do
      justify = col_config&.dig(:align) == :center ? ' justify-center' : ''
      div(class: "flex items-center gap-1#{justify}") do
        if col_title.present?
          raw col_title.to_s.html_safe # rubocop:disable Rails/OutputSafety
        else
          span(class: 'sr-only') { t('admin.labels.actions') }
        end
        render_sort_icon(index) if sortable
      end
    end
  end

  def render_sort_icon(index)
    span(class: 'text-gray-400 opacity-0 group-hover:opacity-100',
         data_admin_table_target: 'sortIcon',
         data_column: @columns[index]) do
      icon(:arrow_up_down, size: nil)
    end
  end

  def render_loading_row
    tr do
      td(colspan: @columns.length.to_s, class: 'px-6 py-12 text-center') do
        div(class: 'flex flex-col items-center justify-center text-gray-500') do
          span(class: 'grid size-8 text-placecal-orange', style: 'animation: spin 1s linear infinite;') do
            icon(:circle, size: nil, css_class: 'opacity-25 stroke-4 row-start-1 col-start-1')
            icon(:spinner, size: nil, css_class: 'opacity-75')
          end
          span(class: 'mt-2 text-sm') { t('admin.datatable.loading') }
        end
      end
    end
  end

  def render_footer
    div(class: 'px-6 py-4 border-t border-gray-200 bg-gray-50 flex flex-col sm:flex-row ' \
               'sm:items-center sm:justify-between gap-4') do
      div(data_admin_table_target: 'info', class: 'text-sm text-gray-600')
      nav(aria_label: 'Table navigation') do
        ul(class: 'inline-flex items-center gap-1', data_admin_table_target: 'pagination')
      end
    end
  end
end
