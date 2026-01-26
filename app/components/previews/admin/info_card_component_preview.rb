# frozen_string_literal: true

# @label Info Card
class Admin::InfoCardComponentPreview < ViewComponent::Preview
  # @label Default (Orange)
  def default
    render(Admin::InfoCardComponent.new(
             icon: :calendar,
             label: 'Calendars',
             value: 5,
             color: :orange
           ))
  end

  # @label Info Color
  def info_color
    render(Admin::InfoCardComponent.new(
             icon: :user,
             label: 'Users',
             value: 12,
             color: :info
           ))
  end

  # @label Success Color
  def success_color
    render(Admin::InfoCardComponent.new(
             icon: :check_circle,
             label: 'Active',
             value: 'Yes',
             color: :success
           ))
  end

  # @label Error Color
  def error_color
    render(Admin::InfoCardComponent.new(
             icon: :x_circle,
             label: 'Errors',
             value: 3,
             color: :error
           ))
  end

  # @label Warning Color
  def warning_color
    render(Admin::InfoCardComponent.new(
             icon: :warning,
             label: 'Pending',
             value: 7,
             color: :warning
           ))
  end

  # @label Neutral Color
  def neutral_color
    render(Admin::InfoCardComponent.new(
             icon: :info,
             label: 'Status',
             value: 'N/A',
             color: :neutral
           ))
  end

  # @label With Block Content
  def with_block_content
    render(Admin::InfoCardComponent.new(
             icon: :partner,
             label: 'Partner',
             color: :orange
           )) do
      '<a href="#" class="font-semibold link link-hover text-placecal-orange">Riverside Community Hub</a>'.html_safe
    end
  end
end
