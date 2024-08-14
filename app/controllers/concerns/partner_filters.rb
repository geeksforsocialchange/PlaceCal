# frozen_string_literal: true

class PartnerFilters
  attr_reader :neighbourhoods, :neighbourhood_names

  def initialize(current_site, neighbourhood_names, params)
    @current_neighbourhood_name = params[:neighbourhood_name]
    @current_category_id = params[:category]
    @include_mode = params[:category_mode] # include/exclude
    @current_category = Category.where(id: @current_category_id).first if @current_category_id.present?

    @neighbourhood_names = neighbourhood_names
    @badge_zoom_level = current_site.badge_zoom_level
    @site_neighbourhood_ids = current_site.owned_neighbourhood_ids
  end

  def neighbourhood_active?
    @current_neighbourhood_name.present?
  end

  def category_active?
    @current_category.present?
  end

  def current_neighbourhood_name?(neighbourhood_name)
    @current_neighbourhood_name.present? && (@current_neighbourhood_name == neighbourhood_name)
  end

  def current_category?(category)
    @current_category.present? && (@current_category.id == category.id)
  end

  def apply_to(query = Partner)
    apply_neighbourhood_filter(apply_category_filter(query))
  end

  def categories
    # only return categories that have partners
    #   where those partners have addresses or service areas
    #     in the neighbourhoods of the site

    @categories ||= Category
                    .joins(:partner_tags)
                    .left_joins(:partner_tags)
                    .left_joins(partners: %i[address service_areas])
                    .where(
                      '(addresses.neighbourhood_id in (:neighbourhood_ids) OR service_areas.neighbourhood_id in (:neighbourhood_ids))',
                      neighbourhood_ids: @site_neighbourhood_ids
                    )
                    .group('tags.id')
                    .having('count(partner_tags.tag_id) > 0')
                    .having('(count(addresses.id) > 0 OR count(service_areas.id) > 0)')
                    .order(:name)
  end

  def show_category_filter?
    categories.present?
  end

  def render_filters(view)
    view.render partial: 'partners/filters', locals: { filters: self }
  end

  def include_mode?
    !exclude_mode?
  end

  def exclude_mode?
    @include_mode == 'exclude'
  end

  def reset_categories(url)
    url.sub(/(&|)category=\d*/, '').sub(/(&|)category_mode=(include|exclude)/, '')
  end

  def reset_neighbourhoods(url)
    url.sub(/(&|)neighbourhood_name=(\w|[+])*/, '')
  end

  private

  def apply_category_filter(query = Partner)
    return query unless category_active?

    if exclude_mode?
      return query
             .left_joins(:partner_tags)
             .where('(partner_tags.id IS NULL) OR (partner_tags.tag_id != ?)', @current_category.id)
    end

    query
      .joins(:partner_tags)
      .where(partner_tags: { tag_id: @current_category.id })
  end

  def apply_neighbourhood_filter(query = Partner)
    return query unless neighbourhood_active?

    query.for_neighbourhood_name_filter(query.all, @badge_zoom_level, @current_neighbourhood_name)
  end
end
