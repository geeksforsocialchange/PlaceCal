# frozen_string_literal: true

# @label Related Items List
class Admin::RelatedItemsListComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    items = [
      OpenStruct.new(id: 1, name: 'Weekly Activities', source: 'Google Calendar'),
      OpenStruct.new(id: 2, name: 'Special Events', source: 'iCal Feed'),
      OpenStruct.new(id: 3, name: 'Community Meetups', source: 'Eventbrite')
    ]

    render(Admin::RelatedItemsListComponent.new(
             items: items,
             title_attr: :name,
             subtitle_attr: :source,
             edit_path: ->(item) { "/admin/calendars/#{item.id}/edit" }
           ))
  end

  # @label Without Subtitle
  def without_subtitle
    items = [
      OpenStruct.new(id: 1, name: 'Admin User'),
      OpenStruct.new(id: 2, name: 'Editor User')
    ]

    render(Admin::RelatedItemsListComponent.new(
             items: items,
             title_attr: :name,
             edit_path: ->(item) { "/admin/users/#{item.id}/edit" }
           ))
  end

  # @label Empty State
  def empty
    render(Admin::RelatedItemsListComponent.new(
             items: [],
             title_attr: :name,
             edit_path: ->(_item) { '#' },
             empty_message: 'No calendars linked to this partner'
           ))
  end
end
