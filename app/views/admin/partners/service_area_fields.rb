# frozen_string_literal: true

class Views::Admin::Partners::ServiceAreaFields < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private
  prop :partner, Partner, reader: :private

  def view_template
    can_remove = !form.object.neighbourhood_id ||
                 current_user.can_edit_partners_neighbourhood_by_id?(form.object.neighbourhood_id, partner.id)

    if form.object.neighbourhood.present?
      NeighbourhoodCard(
        neighbourhood: form.object.neighbourhood,
        show_header: false,
        show_remove: can_remove,
        form: form
      )
    else
      CascadingNeighbourhoodFields(form: form, show_remove: can_remove)
    end
  end
end
