# frozen_string_literal: true

class NavigationPreview < Lookbook::Preview
  # @label Directory (no site)
  def directory
    render Components::Shared::Navigation.new(
      navigation: PreviewSupport.sample_navigation,
      site: nil
    )
  end
end
