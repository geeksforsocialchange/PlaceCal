# frozen_string_literal: true

# The image an event's source gives it, downloaded and stored on PlaceCal
module EventImage
  extend ActiveSupport::Concern

  included do
    # A download, type or size failure leaves the event without an image instead of failing its save
    mount_uploader :image, EventImageUploader, validate_download: false, validate_integrity: false, validate_processing: false
  end

  # Downloads only when the source's URL changes, so an unchanged import fetches nothing
  def image_source_url=(url)
    url = url.presence
    return if url == image_source_url

    self.remote_image_url = url if url
    self.remove_image = true if url.nil? || image.blank?
    # A failed download is tried again next import; a file that isn't a usable image is not
    super(image_download_error ? nil : url)
  end
end
