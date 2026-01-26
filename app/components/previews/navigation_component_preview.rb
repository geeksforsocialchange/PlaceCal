# frozen_string_literal: true

class NavigationComponentPreview < ViewComponent::Preview
  # @label Default Site
  def default
    site = OpenStruct.new(
      name: 'PlaceCal Manchester',
      slug: 'manchester',
      logo: nil,
      default_site?: false
    )
    render(NavigationComponent.new(
             navigation: [['Events', '/events'], ['Partners', '/partners'], ['About', '/about']],
             site: site
           ))
  end

  # @label With Logo
  def with_logo
    site = OpenStruct.new(
      name: 'The Trans Dimension',
      slug: 'trans-dimension',
      logo: OpenStruct.new(url: '/images/logo.png'),
      default_site?: false
    )
    render(NavigationComponent.new(
             navigation: [['Events', '/events'], ['Partners', '/partners'], ['News', '/news']],
             site: site
           ))
  end

  # @label Default Site (PlaceCal)
  def placecal_default
    site = OpenStruct.new(
      name: 'PlaceCal',
      slug: 'placecal',
      logo: nil,
      default_site?: true
    )
    render(NavigationComponent.new(
             navigation: [['Find PlaceCal', '/find-placecal'], ['About', '/about'], ['Contact', '/contact']],
             site: site
           ))
  end
end
