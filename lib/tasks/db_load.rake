# frozen_string_literal: true

namespace :db do
  namespace :load do
    desc 'Loads the default category tags into the tags table'
    task default_categories: :environment do
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
        'Places of worship',
        'Community Hubs',
        'Housing',
        'Legal Advice',
        'Immigration',
        'LGBTQ+',
        'Communities of Colour'
      ]

      categories.each do |category|
        CategoryTag.find_or_create_by!(name: category)
      end
    end
  end
end
