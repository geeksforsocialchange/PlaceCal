# frozen_string_literal: true

namespace :images do
  desc 'Make the WebP copies of every partner and event image'
  task sidebar_webp: :environment do
    { Partner => :image, Event => :image }.each do |model, column|
      done = missing = failed = 0
      model.where.not(column => [nil, '']).find_each do |record|
        image = record.public_send(column)
        next missing += 1 unless image.file&.exists?

        image.recreate_versions!(:standard_webp, :retina_webp)
        done += 1
      rescue StandardError => e
        failed += 1
        puts "#{model} #{record.id}: failed, #{e.message}"
      end
      puts "#{model}: #{done} done, #{missing} with no file, #{failed} failed"
    end
  end

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
