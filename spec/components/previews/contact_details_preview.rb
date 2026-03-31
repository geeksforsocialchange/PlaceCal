# frozen_string_literal: true

class ContactDetailsPreview < Lookbook::Preview
  # @label With all contact info
  def with_all_contacts
    partner = Partner.new(
      name: "Hulme Community Hub",
      facebook_link: "HulmeCommunity",
      twitter_handle: "hulme_cc",
      instagram_handle: "hulmecc"
    )
    render Components::ContactDetails.new(
      partner: partner,
      email: "info@hulme.example.org",
      phone: "0161 234 5678",
      url: "https://hulme.example.org"
    )
  end

  # @label Minimal (no contact info)
  def minimal
    partner = Partner.new(name: "Mystery Organisation")
    render Components::ContactDetails.new(partner: partner)
  end
end
