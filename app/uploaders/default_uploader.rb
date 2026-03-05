# frozen_string_literal: true

require 'svg_sanitizer'

class DefaultUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # remember to change max_request_body in config/deploy.yml proxy settings
  def size_range
    (1.byte)..(10.megabytes)
  end

  # Strip script tags, event handlers, and other dangerous content from SVGs.
  # Runs automatically after upload for any file with an .svg extension.
  process :sanitize_svg

  def sanitize_svg
    return unless file && File.extname(file.file).casecmp('.svg').zero?

    sanitized = SvgSanitizer.sanitize(file.read)
    File.write(file.file, sanitized)
  end
end
