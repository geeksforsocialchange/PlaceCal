# frozen_string_literal: true

class Views::Admin::Calendars::Edit < Views::Admin::Base
  prop :calendar, Calendar, reader: :private

  def view_template
    render Components::Admin::PageHeader.new(model_name: 'Calendar', title: calendar.name, id: calendar.id)
    render Views::Admin::Calendars::Form.new(calendar: calendar)
  end
end
