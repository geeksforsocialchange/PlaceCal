# frozen_string_literal: true

class PartnerCategoryFilter
  def initialize(site, params)
    @current_category_id = params[:category]
    @current_category = Category.where(id: @current_category_id).first if @current_category_id.present?

    @include_mode = params['category_mode'] # include/exclude
    @site_neighbourhood_ids = site.owned_neighbourhood_ids
  end

  def active?
    @current_category.present?
  end

  def apply_to(query = Partner)
    return query unless active?

    if exclude_mode?
      return query
             .left_joins(:partner_tags)
             .where('(partner_tags.id IS NULL) OR (partner_tags.tag_id != ?)', @current_category.id)
    end

    query
      .joins(:partner_tags)
      .where(partner_tags: { tag_id: @current_category.id })
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

  def show_filter?
    categories.present?
  end

  def current_category?(category)
    @current_category.present? && (@current_category.id == category.id)
  end

  def render_filter(view)
    view.render partial: 'partners/category_filter', locals: { filter: self, title: 'Category' }
  end

  def include_mode?
    !exclude_mode?
  end

  def exclude_mode?
    @include_mode == 'exclude'
  end

  def reset(url)
    url.sub(/(&|)category=\d*/, '').sub(/(&|)category_mode=(include|exclude)/, '')
  end
end
