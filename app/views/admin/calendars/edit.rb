# frozen_string_literal: true

class Views::Admin::Calendars::Edit < Views::Admin::Base
  prop :calendar, _Any, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Calendar', title: calendar.name, id: calendar.id)
    raw(view_context.render('form'))
  end
end
