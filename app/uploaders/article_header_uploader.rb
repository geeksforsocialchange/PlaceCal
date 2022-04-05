# frozen_string_literal: true

class ArticleHeaderUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  process resize_to_fill: [1920, 1280, :center]

  version :highres do
    process resize_to_fill: [1272, 714, :center]
  end

  def extension_allowlist
    %w[svg jpg jpeg png]
  end
end
