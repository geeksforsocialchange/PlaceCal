# frozen_string_literal: true

class TagFilter
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
    when 'category' then query = query.where(type: 'Category')
    when 'partnership' then query = query.where(type: 'Partnership')
    when 'facility' then query = query.where(type: 'Facility')
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
    text = 'Next &raquo;'.html_safe
    per_page_value = @per_page || 10

    return tag_link_to(page, text, false) if model.count < per_page_value

    page_num = (@page_num || 1) + 1
    tag_link_to page, text, true, page_num: page_num
  end

  def prev_page_link(page, _model)
    text = '&laquo; Prev'
    page_num = (@page_num || 1) - 1

    return tag_link_to(page, text, false) if page_num < 1

    tag_link_to page, text, true, page_num: page_num
  end

  # rubocop:disable Rails/OutputSafety
  def tag_link_to(page, text, enabled, options = {})
    text = text.html_safe

    unless enabled
      html = "<span class='btn btn-outline-secondary disabled'>#{text}</span>"
      return html.html_safe
    end

    options[:type]     ||= @type if @type.present?
    options[:per_page] ||= @per_page if @per_page.present?
    options[:page_num] ||= @page_num if @page_num.present?
    options[:name]     ||= @name if @name.present?

    path = page.admin_tags_path(options).html_safe

    page.link_to text, path, class: 'btn btn-secondary'
  end

  # rubocop:enable Rails/OutputSafety
end
