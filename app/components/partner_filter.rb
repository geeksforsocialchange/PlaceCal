# frozen_string_literal: true

class Components::PartnerFilter < Components::Base
  include Phlex::Rails::Helpers::FormWith

  prop :site, ::Site
  prop :selected_category, _Nilable(String), default: nil
  prop :selected_neighbourhood, _Nilable(String), default: nil
  prop :selected_partnership, _Nilable(String), default: nil

  def after_initialize
    @selected_category = @selected_category.to_i
    @selected_neighbourhood = @selected_neighbourhood.to_i
    @selected_partnership = @selected_partnership.to_i
    @query = PartnersQuery.new(site: @site)
  end

  def view_template
    form_with(**form_data, class: 'filters__form') do
      div(class: 'breadcrumb__element breadcrumb__element--last') do
        span { 'Filter by:' }
        render_partnership_filter if show_partnership_filter?
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

  def render_partnership_filter
    div(class: 'breadcrumb__filters filters') do
      Filter(
        name: 'partnership',
        label: 'Partnership',
        items: partnership_items,
        selected_id: @selected_partnership,
        controller: 'partner-filter-component',
        toggle_action: 'togglePartnership',
        submit_action: 'submitPartnership',
        reset_action: 'resetPartnership'
      )
    end
  end

  def render_category_filter
    div(class: 'breadcrumb__filters filters') do
      Filter(
        name: 'category',
        label: 'Category',
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
        label: 'Neighbourhood',
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
      link_to('Reset filters', partners_path, class: 'filters__link', data: { turbo_frame: 'partner_previews' })
    end
  end

  def categories
    @categories ||= @query.categories_with_counts
  end

  def category_items
    categories.map { |c| { id: c[:category].id, name: c[:category].name, count: c[:count] } }
  end

  def show_category_filter?
    categories.length > 1
  end

  def neighbourhoods
    @neighbourhoods ||= @query.neighbourhoods_with_counts
  end

  def neighbourhood_items
    neighbourhoods.map { |n| { id: n[:neighbourhood].id, name: n[:neighbourhood].name, count: n[:count] } }
  end

  def show_neighbourhood_filter?
    neighbourhoods.length > 1
  end

  def partnerships
    @partnerships ||= @query.partnerships_with_counts
  end

  def partnership_items
    partnerships.map { |p| { id: p[:partnership].id, name: p[:partnership].name, count: p[:count] } }
  end

  def show_partnership_filter?
    @site&.directory_site? && partnerships.length > 1
  end

  def any_filter_active?
    @selected_category.positive? || @selected_neighbourhood.positive? || @selected_partnership.positive?
  end
end
