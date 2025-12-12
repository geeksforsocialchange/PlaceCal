# frozen_string_literal: true

require_relative '../../lib/normal_island'

module SeedTags
  def self.run
    $stdout.puts 'Tags'

    # Create category tags
    NormalIsland::TAGS[:categories].each do |tag_data|
      tag = Tag.create!(
        name: tag_data[:name],
        slug: tag_data[:name].parameterize,
        type: tag_data[:type],
        description: "Events and activities related to #{tag_data[:name].downcase}"
      )
      $stdout.puts "  Created category: #{tag.name}"
    end

    # Create facility tags
    NormalIsland::TAGS[:facilities].each do |tag_data|
      tag = Tag.create!(
        name: tag_data[:name],
        slug: tag_data[:name].parameterize,
        type: tag_data[:type],
        description: "Venue has: #{tag_data[:name]}"
      )
      $stdout.puts "  Created facility: #{tag.name}"
    end

    # Create partnership tags
    NormalIsland::TAGS[:partnerships].each do |tag_data|
      tag = Tag.create!(
        name: tag_data[:name],
        slug: tag_data[:name].parameterize,
        type: tag_data[:type],
        description: "Part of the #{tag_data[:name]} partnership"
      )
      $stdout.puts "  Created partnership: #{tag.name}"
    end
  end
end

SeedTags.run
