# frozen_string_literal: true

class Views::Admin::Users::NeighbourhoodsUserFields < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    if form.object.neighbourhood.present?
      NeighbourhoodCard(neighbourhood: form.object.neighbourhood, show_header: false, show_remove: true, form:)
    else
      CascadingNeighbourhoodFields(
        form:,
        show_remove: true,
        relation_type: nil,
        title: t('admin.cascading_neighbourhood.new_neighbourhood')
      )
    end
  end
end
