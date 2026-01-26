# frozen_string_literal: true

class FooterPreview < ViewComponent::Preview
  # @label Default
  def default
    site = OpenStruct.new(
      name: 'PlaceCal Manchester',
      slug: 'manchester',
      tagline: 'A community calendar for Manchester',
      site_admin: nil,
      footer_logo: nil,
      supporters: []
    )
    render(Footer.new(site))
  end

  # @label With Site Admin
  def with_site_admin
    admin = OpenStruct.new(
      full_name: 'Jane Smith',
      phone: '0161 123 4567',
      email: 'jane@example.org'
    )
    site = OpenStruct.new(
      name: 'Hulme & Moss Side Community Events',
      slug: 'hulme',
      tagline: 'Bringing together community events across Hulme and Moss Side neighbourhoods',
      site_admin: admin,
      footer_logo: nil,
      supporters: []
    )
    render(Footer.new(site))
  end
end
