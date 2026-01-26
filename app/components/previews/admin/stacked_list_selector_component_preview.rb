# frozen_string_literal: true

# @label Stacked List Selector
class Admin::StackedListSelectorComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    items = [
      OpenStruct.new(id: 1, name: 'Riverside Community Hub'),
      OpenStruct.new(id: 2, name: 'Town Hall Events')
    ]

    options = [
      ['Riverside Community Hub', 1],
      ['Town Hall Events', 2],
      ['Library Services', 3],
      ['Youth Centre', 4]
    ]

    render(Admin::StackedListSelectorComponent.new(
             field_name: 'user[partner_ids][]',
             items: items,
             options: options,
             icon_name: :partner,
             icon_color: 'bg-emerald-100 text-emerald-600',
             empty_text: 'No partners assigned',
             add_placeholder: 'Add a partner...'
           ))
  end

  # @label Empty State
  def empty
    render(Admin::StackedListSelectorComponent.new(
             field_name: 'user[partnership_ids][]',
             items: [],
             options: [
               ['Age Friendly Manchester', 1],
               ['Hulme Together', 2]
             ],
             icon_name: :partnership,
             icon_color: 'bg-purple-100 text-purple-600',
             empty_text: 'No partnerships assigned'
           ))
  end

  # @label Read Only
  def read_only
    items = [
      OpenStruct.new(id: 1, name: 'Age Friendly Manchester'),
      OpenStruct.new(id: 2, name: 'Hulme Together')
    ]

    render(Admin::StackedListSelectorComponent.new(
             field_name: 'partner[partnership_ids][]',
             items: items,
             icon_name: :partnership,
             icon_color: 'bg-purple-100 text-purple-600',
             read_only: true,
             link_path: :edit_admin_partnership_path
           ))
  end

  # @label With Tom Select
  def with_tom_select
    items = [
      OpenStruct.new(id: 1, name: 'Community Centre')
    ]

    options = [
      ['Community Centre', 1],
      ['Library', 2],
      ['Sports Hall', 3],
      ['Youth Club', 4],
      ['Senior Centre', 5]
    ]

    render(Admin::StackedListSelectorComponent.new(
             field_name: 'site[partner_ids][]',
             items: items,
             options: options,
             icon_name: :partner,
             icon_color: 'bg-orange-100 text-orange-600',
             use_tom_select: true,
             add_placeholder: 'Search for partners...'
           ))
  end
end
