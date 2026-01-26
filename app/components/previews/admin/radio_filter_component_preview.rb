# frozen_string_literal: true

# @label Radio Filter
class Admin::RadioFilterComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(Admin::RadioFilterComponent.new(
             column: 'has_events',
             label: 'Has Events',
             options: [
               { value: 'yes', label: 'Yes' },
               { value: 'no', label: 'No' }
             ]
           ))
  end

  # @label Without All Button
  def without_all
    render(Admin::RadioFilterComponent.new(
             column: 'status',
             label: 'Status',
             options: [
               { value: 'active', label: 'Active' },
               { value: 'inactive', label: 'Inactive' },
               { value: 'pending', label: 'Pending' }
             ],
             show_all: false
           ))
  end

  # @label Multiple Options
  def multiple_options
    render(Admin::RadioFilterComponent.new(
             column: 'role',
             label: 'User Role',
             options: [
               { value: 'root', label: 'Root' },
               { value: 'editor', label: 'Editor' },
               { value: 'citizen', label: 'Citizen' }
             ]
           ))
  end
end
