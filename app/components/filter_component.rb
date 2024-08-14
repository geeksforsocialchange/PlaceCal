# frozen_string_literal: true

class FilterComponent < ViewComponent::Base
  def initialize(partners:, site:)
    super
    @partners = partners
    @site = site
  end

  def categories
    @partners.map(&:categories).flatten.uniq.sort_by(&:name)
  end

  def current_category?(_category)
    false
  end

  def show_category_filter?
    true
  end

  def include_mode?
    true
  end

  def exclude_mode?
    false
  end

  def neighbourhoods
    @partners.map(&:neighbourhoods).flatten.uniq.sort_by(&:name)
  end
end
