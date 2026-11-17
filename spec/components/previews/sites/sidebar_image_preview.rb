# frozen_string_literal: true

# The image at the top of a partner or event page's side column on a site (Shared::SidebarImage)
class Sites::SidebarImagePreview < Lookbook::Preview
  # @label Poster
  def poster
    render Components::Shared::SidebarImage.new(src: image("event-poster.jpg"), alt: "Spring Craft Fair")
  end

  # @label Photo
  def photo
    render Components::Shared::SidebarImage.new(src: image("event-photo.jpg"), alt: "Walk in the park")
  end

  private

  def image(name) = ActionController::Base.helpers.image_path("lookbook/#{name}")
end
