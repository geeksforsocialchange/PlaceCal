# frozen_string_literal: true

require_relative '../../lib/normal_island'

module SeedTags
  def self.run
    $stdout.puts 'Tags'

    { categories: 'category', facilities: 'facility', partnerships: 'partnership' }.each do |group, label|
      NormalIsland::TAGS[group].each do |tag_data|
        tag = Tag.find_or_create_by!(name: tag_data[:name], type: tag_data[:type]) do |t|
          t.slug = tag_data[:name].parameterize
          t.description = case tag_data[:type]
                          when 'Category' then "Events and activities related to #{tag_data[:name].downcase}"
                          when 'Facility' then "Venue has: #{tag_data[:name]}"
                          when 'Partnership' then "Part of the #{tag_data[:name]} partnership"
                          end
        end
        $stdout.puts "  #{tag.previously_new_record? ? 'Created' : 'Found'} #{label}: #{tag.name}"
      end
    end
  end
end

SeedTags.run
