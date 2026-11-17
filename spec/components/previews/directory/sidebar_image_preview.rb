# frozen_string_literal: true

# @display context directory
# The image at the top of a partner or event page's sidebar on the directory (Shared::SidebarImage)
class Directory::SidebarImagePreview < Lookbook::Preview
  # @label Poster
  def poster
    render Components::Shared::SidebarImage.new(src: image("event-poster.jpg"), alt: "Spring Craft Fair", layout: :directory)
  end

  # @label Photo
  def photo
    render Components::Shared::SidebarImage.new(src: image("event-photo.jpg"), alt: "Walk in the park", layout: :directory)
  end

  private

  def image(name) = ActionController::Base.helpers.image_path("lookbook/#{name}")
end
