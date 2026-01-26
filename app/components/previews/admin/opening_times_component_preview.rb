# frozen_string_literal: true

# @label Opening Times
# @note Requires form builder and Partner model - showing static HTML approximation
class Admin::OpeningTimesComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render_with_template(template: 'admin/opening_times_component_preview/default')
  end
end
