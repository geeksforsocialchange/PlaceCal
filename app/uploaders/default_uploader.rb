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

  # Runs on every upload with an .svg extension.
  process :sanitize_svg

  def sanitize_svg
    return unless file && File.extname(file.file).casecmp('.svg').zero?

    sanitized = SvgSanitizer.sanitize(file.read)
    raise CarrierWave::ProcessingError, I18n.t('activerecord.errors.messages.invalid_svg') if sanitized.nil?

    File.write(file.file, sanitized)
  end
end
