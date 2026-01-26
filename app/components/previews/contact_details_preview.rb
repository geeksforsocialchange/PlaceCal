# frozen_string_literal: true

class ContactDetailsPreview < ViewComponent::Preview
  # @label Full Contact Details
  def full_details
    partner = OpenStruct.new(
      name: 'Hulme Community Garden Centre',
      public_phone: '0161 123 4567',
      valid_public_phone?: true,
      public_email: 'info@hulme-garden.org',
      url: 'https://hulme-garden.org',
      facebook_link: 'HulmeGarden',
      twitter_handle: 'hulme_garden',
      instagram_handle: 'hulme_garden'
    )
    render(ContactDetails.new(partner: partner))
  end

  # @label Minimal Details
  def minimal
    partner = OpenStruct.new(
      name: 'Community Centre',
      public_phone: nil,
      valid_public_phone?: false,
      public_email: 'hello@example.org',
      url: nil,
      facebook_link: nil,
      twitter_handle: nil,
      instagram_handle: nil
    )
    render(ContactDetails.new(partner: partner))
  end

  # @label With Custom Overrides
  def with_overrides
    partner = OpenStruct.new(
      name: 'Youth Club',
      public_phone: '0161 999 8888',
      valid_public_phone?: true,
      public_email: 'youth@example.org',
      url: 'https://youth-club.org',
      facebook_link: nil,
      twitter_handle: nil,
      instagram_handle: nil
    )
    render(ContactDetails.new(
             partner: partner,
             email: 'events@youth-club.org',
             phone: '0800 123 456'
           ))
  end
end
