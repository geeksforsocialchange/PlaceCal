# frozen_string_literal: true

class EventImageUploader < DefaultUploader
  EXTENSIONS = { 'image/jpeg' => 'jpg', 'image/png' => 'png', 'image/gif' => 'gif', 'image/webp' => 'webp' }.freeze

  process resize_to_fit: [1200, 1200]

  # Checked by content, since source URLs often have no extension (Eventbrite's end in a date)
  def content_type_allowlist
    EXTENSIONS.keys
  end

  # A new name per download, so a changed image isn't served from the browser's cache
  def filename
    stored_name
  end

  private

  # Not @filename: CarrierWave sets that to the source's name while caching
  def stored_name
    @stored_name ||= "#{SecureRandom.hex(8)}.#{EXTENSIONS.fetch(file.content_type, 'jpg')}"
  end
end
