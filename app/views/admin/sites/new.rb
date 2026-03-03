# frozen_string_literal: true

class Views::Admin::Sites::New < Views::Admin::Base
  prop :site, _Any, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Site', new_record: true)
    raw(view_context.render('form'))
  end
end
