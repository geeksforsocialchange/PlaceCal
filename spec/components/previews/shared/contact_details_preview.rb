# frozen_string_literal: true

class Shared::ContactDetailsPreview < Lookbook::Preview
  # @label With all contact info
  def with_all_contacts
    partner = Partner.new(
      name: "Hulme Community Hub",
      social_links: [
        "https://bsky.app/profile/hulmecc.bsky.social",
        "https://social.coop/@hulmecc",
        "https://www.facebook.com/groups/hulmecommunity",
        "https://www.instagram.com/hulmecc/",
        "https://hulme.example.org/newsletter"
      ]
    )
    render Components::Shared::ContactDetails.new(
      partner:,
      email: "info@hulme.example.org",
      phone: "0161 234 5678",
      url: "https://hulme.example.org"
    )
  end

  # @label Card with a long website address
  # @notes The address truncates and its icon stays the same size as the others.
  # @display context directory
  def card_with_long_url
    partner = Partner.new(name: "Powerhouse Library")
    render Components::Shared::ContactDetails.new(
      partner:,
      email: "powerhouse.library@example.org",
      phone: "0161 234 5678",
      url: "https://www.manchester.gov.uk/directory_record/44123/powerhouse_library/category/1234/libraries_in_the_city_centre_and_surrounding_neighbourhoods?utm_source=placecal",
      variant: :card
    )
  end

  # @label Minimal (no contact info)
  def minimal
    partner = Partner.new(name: "Mystery Organisation")
    render Components::Shared::ContactDetails.new(partner:)
  end
end
