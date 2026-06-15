# frozen_string_literal: true

# Open Graph card images are rendered server-side with libvips (pango + librsvg).
# Pango resolves fonts through fontconfig, so we point it at a private config
# that contains only the PlaceCal brand fonts. This keeps rendering identical
# across development (macOS), CI and production (Debian).
#
# Both variables must be set before pango initialises, i.e. before the first
# Vips::Image.text call in the process.
fonts_dir = Rails.root.join('app/assets/fonts')
cache_dir = Rails.root.join('tmp/cache/fontconfig')
conf_path = Rails.root.join('tmp/og_image_fonts.conf')

FileUtils.mkdir_p(cache_dir)
File.write(conf_path, <<~XML)
  <?xml version="1.0"?>
  <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
  <fontconfig>
    <dir>#{fonts_dir}</dir>
    <cachedir>#{cache_dir}</cachedir>
  </fontconfig>
XML

# On macOS pango defaults to the CoreText backend, which ignores fontconfig.
ENV['PANGOCAIRO_BACKEND'] ||= 'fontconfig'
ENV['FONTCONFIG_FILE'] ||= conf_path.to_s
