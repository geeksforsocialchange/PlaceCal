# frozen_string_literal: true

class Views::Admin::Sites::SitesNeighbourhoodFields < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    return if form.object.relation_type == 'Primary'

    if form.object.neighbourhood.present?
      NeighbourhoodCard(
        neighbourhood: form.object.neighbourhood,
        show_header: false,
        show_remove: true,
        form: form
      )
      raw(form.hidden_field(:relation_type))
    else
      CascadingNeighbourhoodFields(
        form: form,
        relation_type: 'Secondary',
        show_remove: true
      )
    end
  end
end
