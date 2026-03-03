# frozen_string_literal: true

class Views::Admin::Supporters::New < Views::Admin::Base
  prop :supporter, _Any, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Supporter', new_record: true)
    raw(view_context.render('form'))
  end
end
