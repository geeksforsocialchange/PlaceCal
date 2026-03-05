# frozen_string_literal: true

class Views::Admin::Neighbourhoods::Edit < Views::Admin::Base
  prop :neighbourhood, Neighbourhood, reader: :private

  def view_template
    PageHeader(model_name: 'Neighbourhood', title: neighbourhood.name, id: neighbourhood.id)
    div(class: 'mb-6') do
      NeighbourhoodHierarchyBadge(
        neighbourhood: neighbourhood,
        link_each: true,
        show_icons: true
      )
    end
    render Views::Admin::Neighbourhoods::Form.new(neighbourhood: neighbourhood)
  end
end
