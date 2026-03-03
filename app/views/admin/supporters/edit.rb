# frozen_string_literal: true

class Views::Admin::Supporters::Edit < Views::Admin::Base
  prop :supporter, _Any, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Supporter', title: supporter.name, id: supporter.id)
    raw(view_context.render('form'))
  end
end
