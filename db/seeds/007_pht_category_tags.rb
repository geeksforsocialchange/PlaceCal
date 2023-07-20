# frozen_string_literal: true

module SeedPHTCategoryTags
  PHT_CATEGORIES = [
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
  ].freeze

  def self.run
    $stdout.puts 'PHT Category Tags'

    PHT_CATEGORIES.each do |category|
      Category.create! name: category
    end
  end
end

SeedPHTCategoryTags.run
