# frozen_string_literal: true

class NavigationPreview < Lookbook::Preview
  # @label Default site
  def default_site
    render Components::Navigation.new(
      navigation: PreviewSupport.sample_navigation,
      site: nil
    )
  end
end
