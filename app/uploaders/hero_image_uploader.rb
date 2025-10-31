# frozen_string_literal: true

# app/uploaders/hero_image_uploader.rb
class HeroImageUploader < DefaultUploader
  process resize_to_fill: [2260, 700]

  version :standard do
    process resize_to_fill: [1130, 350]
  end

  version :opengraph do
    process resize_to_fill: [1200, 630]
  end

  version :site_preview do
    process resize_to_fill: [160, 160]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_allowlist
    %w[jpg jpeg png webp]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
