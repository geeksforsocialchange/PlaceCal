# frozen_string_literal: true

# @label Empty State
class Admin::EmptyStateComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(Admin::EmptyStateComponent.new(
             icon: :calendar,
             message: 'No calendars found'
           ))
  end

  # @label With Hint
  def with_hint
    render(Admin::EmptyStateComponent.new(
             icon: :partner,
             message: 'No partners yet',
             hint: 'Add a partner to get started with your community calendar.'
           ))
  end

  # @label Custom Size
  def custom_size
    render(Admin::EmptyStateComponent.new(
             icon: :user,
             message: 'No users assigned',
             icon_size: '16',
             padding: 'py-12'
           ))
  end

  # @label Compact
  def compact
    render(Admin::EmptyStateComponent.new(
             icon: :tag,
             message: 'No tags',
             icon_size: '6',
             padding: 'py-4'
           ))
  end
end
