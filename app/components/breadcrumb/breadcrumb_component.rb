# frozen_string_literal: true

# app/components/breadcrumb_component.rb
class BreadcrumbComponent < MountainView::Presenter
  property :trail, default: []
  property :site_name, default: "The Community Calendar"
end
