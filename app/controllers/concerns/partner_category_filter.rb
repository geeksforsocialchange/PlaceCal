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
    # puts "current_category=#{@current_category}"
    # puts "category=#{category}"
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

# <% # this is the front end component of app/controllers/concerns/partner_category_filter.rb
#    %>
#
# <div class="breadcrumb__filters filters">
#   <div class="js-filters-toggle filters__toggle">
#     <a href="#" data-turbo="false"><span class="icon icon--arrow-down">↓</span> <span class="filters__link">Category</span></a>
#   </div>
#
#   <div class="filters__dropdown filters__dropdown--hidden js-filters-dropdown">
#     <%= form_tag partners_path, method: :get, class: 'filters__form' do %>
#     <div class="filters__group" >
#       <% categories.each do |category| %>
#       <div class="filters__option">
#         <%= radio_button_tag 'category', category.id, filter.current_category?(category), class: "tag__button" %>
#         <%= label_tag 'category', category.name, class: "tag__label" %>
#       </div>
#       <% end %>
#     </div>
#
#     <hr>
#
#     <div class="filters__group">
#       <div class="filters__option">
#         <%= radio_button_tag 'mode', 'include', false, class: "include__button" %>
#         <%= label_tag 'mode', 'Include', class: "include__label" %>
#       </div>
#       <div class="filters__option">
#         <%= radio_button_tag 'mode', 'exclude', false, class: "include__button" %>
#         <%= label_tag 'mode', 'Exclude', class: "include__label" %>
#       </div>
#     </div>
#
#     <hr>
#
#     <a href="/partners" class="btn">Reset</a>
#     <%= button_tag 'Filter', name: nil, class: 'btn' %>
#     <% end %>
#   </div>
# </div>
#
#
#
#
#
#
#
#   def tag
#     @current_tag = params[:opts][:id]
#     @include = params[:opts][:include] == '1'
#     site_partners = Partner
#                     .for_site(current_site)
#
#     tag_partners = Tag.find(@current_tag).partners.pluck(:id)
#
#     @partners = if @current_tag
#                   if @include
#                     Partner.where(id: site_partners.pluck(:id) & tag_partners)
#                            .includes(:service_areas, :address)
#                            .order(:name)
#                   else
#                     Partner.where(id: site_partners.pluck(:id) - tag_partners)
#                            .includes(:service_areas, :address)
#                            .order(:name)
#                   end
#                 else
#                   site_partners.order(:name)
#                 end
#
#     # show only partners with no service_areas
#     @map = get_map_markers(@partners, true) if @partners.detect(&:address)
#     # cat_tags = Tag.where(type: 'Category').order(:name)
#     # @categories = cat_tags.filter { |t| (@partners & t.partners).length.positive? }
#     # render 'index'
#     # render 'tag'
#   end
