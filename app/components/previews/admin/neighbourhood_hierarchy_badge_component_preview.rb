# frozen_string_literal: true

# @label Neighbourhood Hierarchy Badge
# @note Requires database records - showing with mock HTML
class Admin::NeighbourhoodHierarchyBadgeComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render_with_template(template: 'admin/neighbourhood_hierarchy_badge_component_preview/default')
  end

  # @label Compact
  def compact
    render_with_template(template: 'admin/neighbourhood_hierarchy_badge_component_preview/compact')
  end

  # @label With Icons
  def with_icons
    render_with_template(template: 'admin/neighbourhood_hierarchy_badge_component_preview/with_icons')
  end

  # @label Truncated
  def truncated
    render_with_template(template: 'admin/neighbourhood_hierarchy_badge_component_preview/truncated')
  end
end
