# frozen_string_literal: true

class Views::Admin::Sites::SitesNeighbourhoodFields < Views::Admin::Base
  prop :form, _Any, reader: :private

  def view_template
    return if form.object.relation_type == 'Primary'

    if form.object.neighbourhood.present?
      render Components::Admin::NeighbourhoodCard.new(
        neighbourhood: form.object.neighbourhood,
        show_header: false,
        show_remove: true,
        form: form
      )
    else
      render Components::Admin::CascadingNeighbourhoodFields.new(
        form: form,
        relation_type: 'Secondary',
        show_remove: true
      )
    end
  end
end
