# frozen_string_literal: true

class Views::Admin::Sites::Edit < Views::Admin::Base
  prop :site, _Any, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Site', title: site.name, id: site.id)
    raw(view_context.render('form'))
  end
end
