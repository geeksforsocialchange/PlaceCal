# frozen_string_literal: true

# app/components/contact_details/contact_details_component.rb
class ContactDetails < ViewComponent::Base
  # rubocop:disable Metrics/ParameterLists
  def initialize(partner: Partner)
    # rubocop:enable Metrics/ParameterLists
    super
    @name = partner.name
    @phone = partner.public_phone
    @url = partner.url
    @email = partner.public_email
    @facebook_link = partner.facebook_link
    @twitter_handle = partner.twitter_handle
    @instagram_handle = partner.instagram_handle
    @is_valid_phone = partner.valid_public_phone?
    @twitter_url = "https://twitter.com/#{partner.twitter_handle}"
    @facebook_url = "https://facebook.com/#{partner.facebook_link}"
    @contact = partner.public_phone || partner.public_email || partner.url || partner.facebook_link || partner.twitter_handle
  end

  def strip_url(target_url)
    target_url.gsub('http://', '')
              .gsub('https://', '')
              .gsub('www.', '')
              .gsub(%r{/$}, '')
  end
end
