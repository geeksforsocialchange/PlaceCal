# frozen_string_literal: true

# @label Radio Filter Group
class Admin::RadioFilterGroupComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render(Admin::RadioFilterGroupComponent.new(
             group_label: 'Permissions',
             filters: [
               {
                 column: 'role',
                 label: 'Role',
                 options: [
                   { value: 'root', label: 'Root' },
                   { value: 'editor', label: 'Editor' }
                 ]
               },
               {
                 column: 'status',
                 label: 'Status',
                 options: [
                   { value: 'active', label: 'Active' },
                   { value: 'invited', label: 'Invited' }
                 ]
               }
             ]
           ))
  end
end
