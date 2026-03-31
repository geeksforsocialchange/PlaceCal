# frozen_string_literal: true

class BreadcrumbPreview < Lookbook::Preview
  # @label Default
  def default
    render Components::Breadcrumb.new(
      trail: [["Events", "/events"]],
      site_name: "The Community Calendar"
    ) { "Monday 15 June 2025" }
  end

  # @label Deep trail
  def deep_trail
    render Components::Breadcrumb.new(
      trail: [["Events", "/events"], ["Partners", "/partners"]],
      site_name: "Hulme & Moss Side"
    ) { "Hulme Community Garden Centre" }
  end
end
