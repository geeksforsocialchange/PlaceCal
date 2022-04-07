# frozen_string_literal: true

# app/uploaders/image_uploader.rb
class ImageUploader < DefaultUploader
  # Process files as they are uploaded:
  process resize_to_fit: [1200, 1200]

  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :retina do
    process resize_to_fit: [840, 1200]
  end

  version :standard do
    process resize_to_fit: [420, 840]
  end

  version :thumb do
    process resize_to_fit: [100, 100]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_whitelist
    %w[jpg jpeg gif png]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details
  # def filename
  #   "something.jpg" if original_filename
  # end
end
