# frozen_string_literal: true

# WebP copies of an uploader's images, served beside the original format through a picture element
module WebpVersions
  extend ActiveSupport::Concern

  # Fixed, because ImageMagick otherwise keeps the source's quality and a high-quality JPEG becomes a larger WebP
  QUALITY = 75

  class_methods do
    # webp_versions(standard: [420, 840]) adds a standard_webp version fitted inside 420 x 840
    def webp_versions(sizes)
      sizes.each do |name, dimensions|
        version :"#{name}_webp" do
          process resize_to_fit: dimensions
          process :convert_to_webp

          define_method(:full_filename) { |for_file| "#{name}_webp_#{File.basename(for_file, '.*')}.webp" }
        end
      end
    end
  end

  def convert_to_webp
    minimagick! { |builder| builder.convert('webp').saver(quality: QUALITY) }
  end

  # webp_srcset(standard: '1x', retina: '2x'), or nil until every copy exists, so a page never offers a missing file
  def webp_srcset(descriptors)
    copies = descriptors.keys.map { |name| public_send(:"#{name}_webp") }
    return unless copies.all? { |copy| copy.file&.exists? }

    copies.zip(descriptors.values).map { |copy, descriptor| "#{copy.url} #{descriptor}" }.join(', ')
  end
end
