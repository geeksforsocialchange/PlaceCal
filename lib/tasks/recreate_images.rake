namespace :recreate_images do

  desc 'Recreate Site hero image'
  task site: :environment do
    Site.find_each { |s| s.hero_image.recreate_versions! }
  end
end
