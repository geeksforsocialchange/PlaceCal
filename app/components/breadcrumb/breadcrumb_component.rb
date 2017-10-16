# app/components/breadcrumb_component.rb
class BreadcrumbComponent < MountainView::Presenter
  property :region
  property :trail, default: []

  def region
    properties[:region] ? properties[:region].titleize : 'Hulme & Moss Side'
  end
end
