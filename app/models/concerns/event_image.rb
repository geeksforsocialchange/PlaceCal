# frozen_string_literal: true

# The image an event's source gives it, downloaded and stored on PlaceCal
module EventImage
  extend ActiveSupport::Concern

  # Prepended so it wraps the store_image! that mount_uploader defines
  module StoresSafely
    # Writing the file can fail where the download didn't (a full disk, a folder the app can't write)
    def store_image!
      super
    rescue StandardError => e
      Rails.logger.warn("[Event] Image for event #{id} not saved: #{e.class}: #{e.message}")
      update_columns(image: nil, image_source_url: nil) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  included do
    # A download, type or size failure leaves the event without an image instead of failing its save
    mount_uploader :image, EventImageUploader, validate_download: false, validate_integrity: false, validate_processing: false
    prepend StoresSafely
  end

  # Downloads only when the source's URL changes, so an unchanged import fetches nothing
  def image_source_url=(url)
    url = url.presence
    return if url == image_source_url

    failed = url && !cache_remote_image(url)
    self.remove_image = true if url.nil? || image.blank?
    # A failed download is tried again next import; a file that isn't a usable image is not
    super(failed || image_download_error ? nil : url)
  end

  private

  # CarrierWave turns download, type and size problems into errors on the event; anything else would end the import
  def cache_remote_image(url)
    self.remote_image_url = url
    true
  rescue StandardError => e
    Rails.logger.warn("[Event] Image from #{url} not cached: #{e.class}: #{e.message}")
    false
  end
end
