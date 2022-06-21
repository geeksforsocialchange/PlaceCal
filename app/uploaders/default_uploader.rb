# frozen_string_literal: true

class DefaultUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # remember to change this in nginx.conf.d/increase_upload_size.conf
  def size_range
    1.byte..10.megabytes
  end
end
