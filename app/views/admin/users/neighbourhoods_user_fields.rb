# frozen_string_literal: true

class Views::Admin::Users::NeighbourhoodsUserFields < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    render Components::Admin::CascadingNeighbourhoodFields.new(
      form: form,
      show_remove: true,
      relation_type: nil,
      title: t('admin.users.fields.new_neighbourhood')
    )
  end
end
