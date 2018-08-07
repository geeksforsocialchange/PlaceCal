# frozen_string_literal: true

# app/components/admin_edit_component.rb
class AdminEditComponent < MountainView::Presenter
  properties :title, :model

  def title
    "Edit #{properties[:model].to_s.humanize}: #{properties[:title]}"
  end
end
