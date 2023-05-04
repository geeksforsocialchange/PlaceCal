# frozen_string_literal: true

class PartnerCategoryFilter
  def initialize(params)
    @current_category_id = params[:category]
    @current_category = Category.where(id: @current_category_id).first if @current_category_id.present?

    @include_mode = params[:mode] # include/exclude
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
    @categories ||= Category
                    .joins(:partner_tags)
                    .group('tags.id')
                    .having('count(tag_id) > 0')
                    .order(:name)
  end

  def show_filter?
    categories.present?
  end

  def current_category?(category)
    @current_category.present? && (@current_category.id == category.id)
  end

  def render_filter(view)
    view.render partial: 'partners/category_filter', locals: { filter: self }
  end

  def include_mode?
    !exclude_mode?
  end

  def exclude_mode?
    @include_mode == 'exclude'
  end
end
