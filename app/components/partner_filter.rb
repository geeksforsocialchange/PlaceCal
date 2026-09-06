# frozen_string_literal: true

class Components::PartnerFilter < Components::Base
  include Phlex::Rails::Helpers::FormWith

  prop :site, ::Site
  prop :selected_category, _Nilable(String), default: nil
  prop :selected_neighbourhood, _Nilable(String), default: nil
  prop :region_tags, Array, default: -> { [] }
  prop :selected_region, _Nilable(::Tag), default: nil

  def after_initialize
    @selected_category = @selected_category.to_i
    @selected_neighbourhood = @selected_neighbourhood.to_i
    @query = PartnersQuery.new(site: @site)
  end

  def view_template
    RegionFilter(tags: @region_tags, selected: @selected_region)

    form_with(**form_data, class: 'filters__form') do
      hidden_field_tag(:region, @selected_region.slug, id: nil) if @selected_region
      div(class: 'breadcrumb__element breadcrumb__element--last') do
        span { t('filters.filter_by') }
        render_category_filter if show_category_filter?
        render_neighbourhood_filter if show_neighbourhood_filter?
        render_reset_link if any_filter_active?
      end
    end
  end

  private

  def form_data
    {
      url: partners_path, method: :get, data: {
        controller: 'partner-filter-component',
        'partner-filter-component-target': 'form',
        'turbo-action': 'advance'
      }
    }
  end

  def render_category_filter
    div(class: 'breadcrumb__filters filters') do
      Filter(
        name: 'category',
        label: t('filters.category'),
        items: category_items,
        selected_id: @selected_category,
        controller: 'partner-filter-component',
        toggle_action: 'toggleCategory',
        submit_action: 'submitCategory',
        reset_action: 'resetCategory'
      )
    end
  end

  def render_neighbourhood_filter
    div(class: 'breadcrumb__filters filters') do
      Filter(
        name: 'neighbourhood',
        label: t('filters.neighbourhood'),
        items: neighbourhood_items,
        selected_id: @selected_neighbourhood,
        controller: 'partner-filter-component',
        toggle_action: 'toggleNeighbourhood',
        submit_action: 'submitNeighbourhood',
        reset_action: 'resetNeighbourhood'
      )
    end
  end

  def render_reset_link
    div(class: 'breadcrumb__filters') do
      link_to(t('filters.reset'), partners_path(@selected_region ? { region: @selected_region.slug } : {}), class: 'filters__link', data: { turbo_frame: 'partner_previews' })
    end
  end

  def categories
    @categories ||= @query.categories_with_counts(scope: filtered_scope(neighbourhood_id: selected_neighbourhood_id))
  end

  def category_items
    categories.map { |c| { id: c[:category].id, name: c[:category].name, count: c[:count] } }
  end

  def show_category_filter?
    categories.length > 1
  end

  def neighbourhoods
    @neighbourhoods ||= @query.neighbourhoods_with_counts(scope: filtered_scope(tag_id: selected_category_id))
  end

  def selected_category_id
    @selected_category if @selected_category.positive?
  end

  def selected_neighbourhood_id
    @selected_neighbourhood if @selected_neighbourhood.positive?
  end

  # Facet counts cross-filter on the other active filters, and always on the
  # selected region so the numbers match the listing. nil means "no extra
  # filtering", which the query treats as the whole site scope.
  def filtered_scope(**filters)
    filters = filters.compact
    filters[:partnership_id] = @selected_region.id if @selected_region
    return nil if filters.empty?

    @query.call(**filters)
  end

  def neighbourhood_items
    neighbourhoods.map { |n| { id: n[:neighbourhood].id, name: n[:neighbourhood].name, count: n[:count] } }
  end

  def show_neighbourhood_filter?
    neighbourhoods.length > 1
  end

  def any_filter_active?
    @selected_category.positive? || @selected_neighbourhood.positive?
  end
end
