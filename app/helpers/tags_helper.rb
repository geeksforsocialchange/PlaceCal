# frozen_string_literal: true

# app/helpers/tags_helper.rb
module TagsHelper
  # rubocop:disable Rails/HelperInstanceVariable
  class TagFilter
    # FormHelper = ActionView::Helpers::FormOptionsHelper
    include ActiveRecord::Sanitization::ClassMethods

    def initialize(params)
      @params = params

      # type
      if params[:type].present?
        value = params[:type].strip
        @type = value if %w[category partnership facility].include?(value)
      end

      # per_page
      if params[:per_page].present?
        value = params[:per_page].strip.to_i
        @per_page = value if [10, 20, 50].include?(value)
      end

      # page_num
      if params[:page_num].present?
        value = params[:page_num].strip.to_i
        @page_num = value if value > 1
      end

      # name
      @name = @params[:name].to_s.strip
    end

    def with_scope(query)
      case @type
      when 'category' then query = query.where(type: 'CategoryTag')
      when 'partnership' then query = query.where(type: 'PartnershipTag')
      when 'facility' then query = query.where(type: 'FacilityTag')
      end

      if @name.present?
        name_value = "%#{sanitize_sql_like(@name)}%"
        query = query.where('name ILIKE :name', name: name_value)
      end

      query
    end

    def with_window(query)
      per_page_value = @per_page || 10
      query = query.limit(per_page_value)

      if @page_num.present?
        page_num_value = (@page_num || 1) - 1

        query = query.offset(page_num_value * per_page_value)
      end

      query
    end

    def options_for_type(page)
      options = [
        ['All', ''],
        %w[Category category],
        %w[Facility facility],
        ['Partnership (Site)', 'partnership']
      ]

      page.options_for_select options, @type
    end

    def options_for_per_page(page)
      options = [
        [10, 10],
        [20, 20],
        [50, 50]
      ]

      page.options_for_select options, @per_page
    end

    def name_value
      @name
    end

    def next_page_link(page, model)
      per_page_value = @per_page || 10
      return 'No more results available' if model.count < per_page_value

      options = {}
      options[:type] = @type if @type.present?
      options[:per_page] = @per_page if @per_page.present?
      options[:page_num] = (@page_num || 1) + 1
      options[:name] = @name if @name.present?

      page.link_to 'Next ...', page.admin_tags_path(options), class: 'btn btn-link'
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable

  def options_for_partners
    policy_scope(Partner).all.order(:name).pluck(:id, :name)
  end

  def options_for_users
    User.all.order(:last_name).collect { |e| [e.admin_name, e.id] }
  end

  def edit_permission_label(value)
    case value.second
    when 'root'
      '<strong>Root</strong>: Non-Root users must explicitly be granted ' \
      'permission to assign this tag'.html_safe
    when 'all'
      '<strong>All</strong>: Any user may assign this tag'.html_safe
    else
      value
    end
  end

  TAG_TO_NAME = {
    'CategoryTag' => 'Category',
    'PartnershipTag' => 'Partnership',
    'FacilityTag' => 'Facility'
  }.freeze

  def human_tag_type(tag)
    TAG_TO_NAME[tag]
  end
end
