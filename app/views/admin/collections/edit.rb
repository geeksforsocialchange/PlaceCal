# frozen_string_literal: true

class Views::Admin::Collections::Edit < Views::Admin::Base
  prop :collection, _Any, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Collection', title: collection.name, id: collection.id)
    raw(view_context.render('form'))
  end
end
