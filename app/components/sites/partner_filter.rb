# frozen_string_literal: true

class Components::Sites::PartnerFilter < Components::Base
  include Phlex::Rails::Helpers::FormWith

  prop :site, ::Site
  prop :selected_category, _Nilable(String), default: nil
  prop :selected_neighbourhood, _Nilable(String), default: nil
  prop :region_tags, Array, default: -> { [] }
  prop :selected_region, _Nilable(::Tag), default: nil
  prop :selected_query, _Nilable(String), default: nil
  # The controller passes its own query so the site partner scope is built once
  # for the listing and the facet counts, not once each.
  prop :query, _Nilable(::PartnersQuery), default: nil

  # Inside the form, filling the bar's row and right-aligned from xl, as the breadcrumb slot is.
  CONTROLS = 'filter-bar__controls w-full max-md:mb-2 xl:w-auto xl:flex-auto xl:justify-end'

  def after_initialize
    @selected_category = @selected_category.to_i
    @selected_neighbourhood = @selected_neighbourhood.to_i
    @query ||= PartnersQuery.new(site: @site)
  end

  def view_template
    UI::Cluster(gap: :md, row_gap: :sm, class: 'filter-bar xl:justify-end') do
      Sites::RegionFilter(tags: @region_tags, selected: @selected_region)

      form_with(**form_data, class: 'filters__form relative') do
        hidden_field_tag(:region, @selected_region.slug, id: nil) if @selected_region
        UI::Cluster(gap: :md, row_gap: :sm, class: CONTROLS) do
          span(class: 'filter-bar__label') { t('filters.filter_by') }
          render_category_filter if show_category_filter?
          render_neighbourhood_filter if show_neighbourhood_filter?
          render_reset_link if any_filter_active?
          render_search
        end
      end
    end
  end

  private

  def form_data
    {
      url: partners_path, method: :get, data: {
        controller: 'partner-filter-component',
        'partner-filter-component-target': 'form',
        action: 'submit->partner-filter-component#guardSubmit',
        'turbo-action': 'advance'
      }
    }
  end

  def render_category_filter
    UI::Cluster(gap: :md, justify: :end, wrap: false, class: 'filters filter-bar__category') do
      Sites::Filter(
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
    UI::Cluster(gap: :md, justify: :end, wrap: false, class: 'filters filter-bar__neighbourhood') do
      Sites::Filter(
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
    UI::Cluster(gap: :md, justify: :end, wrap: false, class: 'filter-bar__reset') do
      link_to(t('filters.reset'), partners_path(@selected_region ? { region: @selected_region.slug } : {}), class: "#{Sites::Breadcrumb::LINK} filters__link",
                                                                                                            data: { turbo_frame: 'partner_previews' })
    end
  end

  # A plain search box, not one of the toggle filters above: it submits the
  # whole form (so region/category/neighbourhood ride along) on Enter, when
  # the field loses focus after a change, or when its clear button empties it.
  def render_search
    UI::Cluster(gap: :md, justify: :end, wrap: false, class: 'filters filter-bar__search') do
      input(
        type: 'search', name: 'q', value: @selected_query,
        class: 'filters__search font-sans border-2 border-rules-dark bg-background py-1 px-2',
        placeholder: t('filters.search_partners'),
        aria_label: t('filters.search_partners'),
        data: { action: 'change->partner-filter-component#submitForm ' \
                        'input->partner-filter-component#submitIfCleared search->partner-filter-component#submitIfCleared' }
      )
    end
  end

  # Facet counts are recomputed at most every few minutes, the same tolerance
  # the news-nav count already accepts (Site#news_article_count). Counting
  # partners per category and neighbourhood was ~100ms a request; on a cache
  # hit it is skipped along with the base-scope build it needed.
  def category_items
    @category_items ||= cached_facet(:categories, neighbourhood: selected_neighbourhood_id) do
      @query.categories_with_counts(scope: filtered_scope(neighbourhood_id: selected_neighbourhood_id))
            .map { |c| { id: c[:category].id, name: c[:category].name, count: c[:count] } }
    end
  end

  def show_category_filter?
    category_items.length > 1
  end

  # The site and the other active filters key the cache, so cross-filtered
  # counts cache separately.
  def cached_facet(facet, **filters, &)
    key = ['partner_facets', facet, @site.id, @selected_region&.id, @selected_query, *filters.values]
    Rails.cache.fetch(key, expires_in: 10.minutes, &)
  end

  def selected_category_id
    @selected_category if @selected_category.positive?
  end

  def selected_neighbourhood_id
    @selected_neighbourhood if @selected_neighbourhood.positive?
  end

  # Facet counts cross-filter on the other active filters, and always on the
  # selected region and search text so the numbers match the listing. nil
  # means "no extra filtering", which the query treats as the whole site scope.
  def filtered_scope(**filters)
    filters = filters.compact
    filters[:partnership_id] = @selected_region.id if @selected_region
    filters[:query] = @selected_query if @selected_query.present?
    return nil if filters.empty?

    @query.call(**filters)
  end

  def neighbourhood_items
    @neighbourhood_items ||= cached_facet(:neighbourhoods, category: selected_category_id) do
      @query.neighbourhoods_with_counts(scope: filtered_scope(tag_id: selected_category_id))
            .map { |n| { id: n[:neighbourhood].id, name: n[:neighbourhood].name, count: n[:count] } }
    end
  end

  def show_neighbourhood_filter?
    neighbourhood_items.length > 1
  end

  def any_filter_active?
    @selected_category.positive? || @selected_neighbourhood.positive?
  end
end
