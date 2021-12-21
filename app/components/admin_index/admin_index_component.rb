# frozen_string_literal: true

# app/components/admin_index_component.rb
class AdminIndexComponent < MountainView::Presenter
  property :additional_links, default: []

  def model_name
    properties[:model].to_s.chop.humanize
  end
end
