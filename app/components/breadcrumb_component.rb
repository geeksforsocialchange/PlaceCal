# frozen_string_literal: true

# app/components/breadcrumb_component.rb
class BreadcrumbComponent < ViewComponent::Base
  def initialize(trail: [], site_name: 'The Community Calendar')
    super()
    @trail = trail
    @site_name = site_name
  end
end
