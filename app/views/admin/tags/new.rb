# frozen_string_literal: true

class Views::Admin::Tags::New < Views::Admin::Base
  prop :tag, _Any, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Tag', new_record: true)
    raw(view_context.render('form'))
  end
end
