# frozen_string_literal: true

namespace :placecal do
  desc 'Creates the default set of PHT category tags'
  task load_pht_category_tags: :environment do
    categories = [
      'Activism',
      'Arts & Crafts',
      'Children & Family',
      'Young Adults',
      'Over 50s',
      'Entertainment',
      'Education',
      'Food',
      'Health & Wellbeing',
      'Outdoors',
      'Sports & Fitness',
      'Places of Worship',
      'Community Hubs',
      'Housing',
      'Legal Advice',
      'Immigration',
      'LGBTQ+',
      'Communities of Colour'
    ]

    categories.each do |category|
      puts category
      Category.find_or_create_by!(name: category)
    end
  end

  desc 'Saves a snapshot of the neighbourhood table (as neighbourhood.json)'
  task save_neighbourhoods: :environment do
    # this is defined in app/models/concerns/save_neighbourhoods.rb
    NeighbourhoodSaver.run
  end
end
