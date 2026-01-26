# frozen_string_literal: true

class PartnerFilterComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    category1 = OpenStruct.new(id: 1, name: 'Arts & Culture')
    category2 = OpenStruct.new(id: 2, name: 'Health & Wellbeing')
    neighbourhood1 = OpenStruct.new(id: 1, name: 'Hulme')
    neighbourhood2 = OpenStruct.new(id: 2, name: 'Moss Side')

    partners = [
      OpenStruct.new(
        name: 'Community Centre',
        categories: [category1],
        neighbourhoods: [neighbourhood1]
      ),
      OpenStruct.new(
        name: 'Health Hub',
        categories: [category2],
        neighbourhoods: [neighbourhood1, neighbourhood2]
      )
    ]

    site = OpenStruct.new(name: 'PlaceCal Manchester')

    render(PartnerFilterComponent.new(
             partners: partners,
             site: site,
             selected_category: 0,
             selected_neighbourhood: 0
           ))
  end

  # @label With Selection
  def with_selection
    category1 = OpenStruct.new(id: 1, name: 'Arts & Culture')
    category2 = OpenStruct.new(id: 2, name: 'Health & Wellbeing')
    neighbourhood1 = OpenStruct.new(id: 1, name: 'Hulme')

    partners = [
      OpenStruct.new(
        name: 'Art Gallery',
        categories: [category1],
        neighbourhoods: [neighbourhood1]
      ),
      OpenStruct.new(
        name: 'Yoga Studio',
        categories: [category2],
        neighbourhoods: [neighbourhood1]
      )
    ]

    site = OpenStruct.new(name: 'PlaceCal Manchester')

    render(PartnerFilterComponent.new(
             partners: partners,
             site: site,
             selected_category: 1,
             selected_neighbourhood: 1
           ))
  end
end
