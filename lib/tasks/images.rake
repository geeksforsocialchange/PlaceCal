# frozen_string_literal: true

namespace :images do
  desc 'Make the WebP copies of every site hero image'
  task hero_webp: :environment do
    Site.find_each do |site|
      next if site.hero_image.blank?

      site.hero_image.recreate_versions!(:webp, :standard_webp)
      puts "#{site.slug}: #{site.hero_image.webp.url}"
    rescue StandardError => e
      puts "#{site.slug}: failed, #{e.message}"
    end
  end
end
