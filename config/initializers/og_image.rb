# frozen_string_literal: true

# Pango reads FONTCONFIG_FILE once, at first use, so it is set for the whole process and its children.
# The config lists the brand fonts, then includes the system's default fonts.conf for everything else.
fonts_dir = Rails.root.join('app/assets/fonts')
cache_dir = Rails.root.join('tmp/cache/fontconfig')
conf_path = Rails.root.join('tmp/og_image_fonts.conf')

FileUtils.mkdir_p(cache_dir)
File.write(conf_path, <<~XML)
  <?xml version="1.0"?>
  <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
  <fontconfig>
    <dir>#{fonts_dir}</dir>
    <include ignore_missing="yes">fonts.conf</include>
    <match target="font">
      <test name="file" compare="contains"><string>#{fonts_dir}</string></test>
      <edit name="hintstyle" mode="assign"><const>hintfull</const></edit>
    </match>
    <cachedir>#{cache_dir}</cachedir>
  </fontconfig>
XML

# On macOS pango defaults to the CoreText backend, which ignores fontconfig.
ENV['PANGOCAIRO_BACKEND'] ||= 'fontconfig'
ENV['FONTCONFIG_FILE'] ||= conf_path.to_s

# Rails 8.1.3.1 (CVE-2026-66066) disables libvips's "unfuzzed" loaders at boot,
# SVG among them. Our OG cards render from SVG we generate, so re-enable that one.
# Uploads are unaffected (CarrierWave + MiniMagick, not vips).
Vips.block('VipsForeignLoadSvg', false) if defined?(Vips) && Vips.respond_to?(:block)
