# frozen_string_literal: true

# app/uploaders/hero_image_uploader.rb
class HeroImageUploader < DefaultUploader
  process resize_to_fit: [2260, 700]

  version :standard do
    process resize_to_fit: [1130, 350]
  end

  version :site_preview do
    process resize_to_fit: [160, 160]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_allowlist
    %w[jpg jpeg png]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
