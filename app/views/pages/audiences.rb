# frozen_string_literal: true

module Views::Pages::Audiences
  AUDIENCE_DATA = [
    { key: :community_groups, title: 'Community groups',
      body: 'Convert your local knowledge into a great community information website.',
      image: 'home/audiences/communities_square.jpg',
      image_alt: 'Stock image of a community group activity' },
    { key: :metropolitan_areas, title: 'Metropolitan areas',
      body: "Publish what's on guides across health, housing, and council sectors.",
      image: 'home/audiences/metro_square.jpg',
      image_alt: 'Stock image of a city centre park' },
    { key: :vcses, title: 'VCSEs',
      body: 'Support community groups in your neighbourhood to work better together.',
      image: 'home/audiences/vcses_square.jpg',
      image_alt: 'Stock image of some people in a community centre' },
    { key: :housing_providers, title: 'Housing providers',
      body: 'Connect your tenants with their local community.',
      image: 'home/audiences/housing_square.jpg',
      image_alt: 'Stock image of some laptops' },
    { key: :social_prescribers, title: 'Social prescribers and GPs',
      body: 'Find hyperlocal social prescriptions in under 30 seconds.',
      image: 'home/audiences/social_square.jpg',
      image_alt: 'Stock image of some laptops' },
    { key: :culture_tourism, title: 'Culture and tourism',
      body: 'Bring more people into your venue, your area or your city.',
      image: 'home/audiences/culture_square.jpg',
      image_alt: 'Stock image of some laptops' }
  ].freeze

  AUDIENCE_PATHS = {
    community_groups: :community_groups_path,
    metropolitan_areas: :metropolitan_areas_path,
    vcses: :vcses_path,
    housing_providers: :housing_providers_path,
    social_prescribers: :social_prescribers_path,
    culture_tourism: :culture_tourism_path
  }.freeze

  private

  def render_audiences(exclude:)
    div(class: 'grid grid__audiences') do
      AUDIENCE_DATA.each do |data|
        next if data[:key] == exclude

        render Components::Audience.new(
          title: data[:title],
          body: data[:body],
          image: data[:image],
          image_alt: data[:image_alt],
          link: send(AUDIENCE_PATHS[data[:key]])
        )
      end
    end
  end
end
