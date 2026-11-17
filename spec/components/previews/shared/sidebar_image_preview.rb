# frozen_string_literal: true

class Shared::SidebarImagePreview < Lookbook::Preview
  # @label Site page, poster
  # @notes Partner and event pages on a site, at the top of the side column.
  def site_poster
    render Components::Shared::SidebarImage.new(src: image("event-poster.jpg"), alt: "Spring Craft Fair")
  end

  # @label Site page, photo
  def site_photo
    render Components::Shared::SidebarImage.new(src: image("event-photo.jpg"), alt: "Walk in the park")
  end

  # @label Directory page, poster
  # @notes PlaceCal's directory partner and event pages, at the top of the sidebar.
  def directory_poster
    render Components::Shared::SidebarImage.new(src: image("event-poster.jpg"), alt: "Spring Craft Fair", layout: :directory)
  end

  # @label Directory page, photo
  def directory_photo
    render Components::Shared::SidebarImage.new(src: image("event-photo.jpg"), alt: "Walk in the park", layout: :directory)
  end

  private

  def image(name) = ActionController::Base.helpers.image_path("lookbook/#{name}")
end
