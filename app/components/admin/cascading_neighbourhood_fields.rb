# frozen_string_literal: true

class Components::Admin::CascadingNeighbourhoodFields < Components::Admin::Base
  prop :form, _Any
  prop :show_remove, _Boolean, default: true
  prop :relation_type, _Nilable(String), default: nil
  prop :title, _Nilable(String), default: nil

  def view_template
    div(
      class: 'nested-fields card bg-base-100 border border-base-300 mb-2',
      data_controller: 'cascading-neighbourhood',
      data_cascading_neighbourhood_selected_id_value: @form.object&.neighbourhood_id,
      data_cascading_neighbourhood_placeholder_country_value: t('admin.cascading_neighbourhood.select_country'),
      data_cascading_neighbourhood_placeholder_region_value: t('admin.cascading_neighbourhood.select_region'),
      data_cascading_neighbourhood_placeholder_county_value: t('admin.cascading_neighbourhood.select_county'),
      data_cascading_neighbourhood_placeholder_district_value: t('admin.cascading_neighbourhood.select_area'),
      data_cascading_neighbourhood_placeholder_ward_value: t('admin.cascading_neighbourhood.select_ward')
    ) do
      div(class: 'card-body p-4 gap-3') do
        render_header
        render_selectors
      end

      raw @form.hidden_field(:relation_type, value: @relation_type) if @relation_type.present?
      raw @form.hidden_field(:neighbourhood_id, data: { cascading_neighbourhood_target: 'output' })
    end
  end

  private

  def render_header
    div(class: 'flex items-center justify-between') do
      div(class: 'flex items-center gap-2') do
        icon(:neighbourhood, size: '4', css_class: 'text-gray-600')
        span(class: 'text-sm font-medium text-base-content/70') do
          @title || t('admin.service_areas.new_area')
        end
      end
      div(class: 'flex items-center gap-1') do
        span(class: 'loading loading-spinner loading-xs hidden',
             data_cascading_neighbourhood_target: 'loading')
        if @show_remove
          raw helpers.nested_form_remove_link(@form, helpers.icon(:trash, size: '4'),
                                              class: 'btn btn-ghost btn-sm btn-square text-error')
        end
      end
    end
  end

  def render_selectors
    div(class: 'space-y-2') do
      render_selector('country', t('admin.cascading_neighbourhood.country'),
                      'countryChanged', enabled: true, initial_option: t('admin.labels.loading'))
      render_selector('region', t('admin.cascading_neighbourhood.region'),
                      'regionChanged', initial_option: t('admin.cascading_neighbourhood.select_region'))
      render_hidden_selector('county', 'countyRow', t('admin.cascading_neighbourhood.county'),
                             'countyChanged', t('admin.cascading_neighbourhood.select_county'))
      render_hidden_selector('district', 'districtRow', t('admin.cascading_neighbourhood.area'),
                             'districtChanged', t('admin.cascading_neighbourhood.select_area'))
      render_hidden_selector('ward', 'wardRow', t('admin.cascading_neighbourhood.ward'),
                             'wardChanged', t('admin.cascading_neighbourhood.select_ward'))
    end
  end

  def render_selector(target, label_text, action, enabled: false, initial_option: '')
    div(class: 'flex items-center gap-3') do
      label(class: 'text-sm text-base-content/70 w-16 shrink-0') { label_text }
      select(
        class: "select select-bordered select-sm bg-base-100 #{'disabled:bg-base-200 disabled:text-gray-400 ' unless enabled}flex-1",
        **{ 'data-cascading-neighbourhood-target' => target },
        **{ 'data-action' => "change->cascading-neighbourhood##{action}" },
        **(enabled ? {} : { disabled: true })
      ) do
        option(value: '') { initial_option }
      end
    end
  end

  def render_hidden_selector(target, row_target, label_text, action, initial_option)
    div(class: 'flex items-center gap-3 hidden',
        **{ 'data-cascading-neighbourhood-target' => row_target }) do
      label(class: 'text-sm text-base-content/70 w-16 shrink-0') { label_text }
      select(
        class: 'select select-bordered select-sm bg-base-100 disabled:bg-base-200 disabled:text-gray-400 flex-1',
        **{ 'data-cascading-neighbourhood-target' => target },
        **{ 'data-action' => "change->cascading-neighbourhood##{action}" },
        disabled: true
      ) do
        option(value: '') { initial_option }
      end
    end
  end
end
