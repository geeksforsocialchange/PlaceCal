# frozen_string_literal: true

module SeedTags
  def self.run
    $stdout.puts 'Tags'

    # category tag
    Tag.create!(
      name: 'Category Tag',
      slug: 'category-tag',
      type: 'Category',
      description: 'A tag about a category'
    )

    # facility tag
    Tag.create!(
      name: 'Facility Tag',
      slug: 'facility-tag',
      type: 'Facility',
      description: 'A tag about a facility'
    )

    # partnership tag
    Tag.create!(
      name: 'Partnership Tag',
      slug: 'partnership-tag',
      type: 'Partnership',
      description: 'A tag about a partnership'
    )
  end
end

SeedTags.run
