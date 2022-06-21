# frozen_string_literal: true

# app/uploaders/supporter_logo_uploader.rb
class SupporterLogoUploader < DefaultUploader
  # Process files as they are uploaded:
  process resize_to_fit: [200, 200], if: :is_raster?
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :standard, if: :is_raster? do
    process resize_to_fit: [100, 100]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_allowlist
    %w[jpg jpeg gif png svg]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

  private

  def is_raster?(new_file)
    File.extname(new_file.file) != '.svg'
  end
end
