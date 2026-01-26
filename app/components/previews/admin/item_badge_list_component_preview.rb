# frozen_string_literal: true

# @label Item Badge List
class Admin::ItemBadgeListComponentPreview < ViewComponent::Preview
  # @label Default (Horizontal)
  def default
    items = [
      OpenStruct.new(id: 1, name: 'Riverside Community Hub'),
      OpenStruct.new(id: 2, name: 'Town Hall Events'),
      OpenStruct.new(id: 3, name: 'Library Services')
    ]

    render(Admin::ItemBadgeListComponent.new(
             items: items,
             icon_name: :partner,
             icon_color: 'bg-emerald-100 text-emerald-600',
             link_path: :edit_admin_partner_path
           ))
  end

  # @label Vertical Layout
  def vertical
    items = [
      OpenStruct.new(id: 1, name: 'Age Friendly Manchester'),
      OpenStruct.new(id: 2, name: 'Hulme Together')
    ]

    render(Admin::ItemBadgeListComponent.new(
             items: items,
             icon_name: :partnership,
             icon_color: 'bg-purple-100 text-purple-600',
             link_path: :edit_admin_partnership_path,
             vertical: true
           ))
  end

  # @label Empty State
  def empty
    render(Admin::ItemBadgeListComponent.new(
             items: [],
             icon_name: :tag,
             icon_color: 'bg-blue-100 text-blue-600',
             link_path: :edit_admin_tag_path,
             empty_text: 'No tags assigned'
           ))
  end

  # @label With Contextual Names
  def with_contextual_names
    items = [
      OpenStruct.new(id: 1, name: 'Hulme', contextual_name: 'Hulme (Ward)'),
      OpenStruct.new(id: 2, name: 'Manchester', contextual_name: 'Manchester (District)')
    ]

    render(Admin::ItemBadgeListComponent.new(
             items: items,
             icon_name: :map_pin,
             icon_color: 'bg-orange-100 text-orange-600',
             link_path: :admin_neighbourhood_path
           ))
  end
end
