# frozen_string_literal: true

class AudiencePreview < Lookbook::Preview
  # @label Default
  def default
    render Components::Audience.new(
      title: "Community Groups",
      image: "home/audiences/communities_wide.jpg",
      image_alt: "Illustration of community groups",
      body: "PlaceCal is for any organisation that runs events or activities for local people."
    )
  end

  # @label With link
  def with_link
    render Components::Audience.new(
      title: "Housing Providers",
      image: "home/audiences/housing_wide.jpg",
      image_alt: "Illustration of housing",
      body: "Help your tenants find community events and services near them.",
      link: "/housing-providers"
    )
  end
end
