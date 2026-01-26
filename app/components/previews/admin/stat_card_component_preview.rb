# frozen_string_literal: true

# @label Stat Card
class Admin::StatCardComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(Admin::StatCardComponent.new(
             label: 'Total Partners',
             value: 42
           ))
  end

  # @label With Icon
  def with_icon
    render(Admin::StatCardComponent.new(
             label: 'Active Calendars',
             value: 156,
             icon: :calendar
           ))
  end

  # @label With Subtitle
  def with_subtitle
    render(Admin::StatCardComponent.new(
             label: 'Events This Month',
             value: 1_234,
             subtitle: '+12% from last month'
           ))
  end

  # @label With Block Content
  def with_block
    render(Admin::StatCardComponent.new(
             label: 'Last Import',
             value: '2 hours ago'
           )) do
      '<span class="text-xs text-success">All imports successful</span>'.html_safe
    end
  end

  # @label Large Number
  def large_number
    render(Admin::StatCardComponent.new(
             label: 'Total Events',
             value: '12,456',
             icon: :calendar,
             subtitle: 'Across all sites'
           ))
  end
end
