# frozen_string_literal: true

# app/components/contact_details/contact_details_component.rb
class ContactDetails < ViewComponent::Base
  # rubocop:disable Metrics/ParameterLists
  def initialize(name: nil, phone: nil, url: nil, email: nil, facebook_link: nil, twitter_handle: nil, instagram_handle: nil, is_valid_phone: nil)
    # rubocop:enable Metrics/ParameterLists
    super
    @name = name
    @phone = phone
    @url = url
    @email = email
    @facebook_link = facebook_link
    @twitter_handle = twitter_handle
    @instagram_handle = instagram_handle
    @is_valid_phone = is_valid_phone
    @twitter_url = "https://twitter.com/#{twitter_handle}"
    @facebook_url = "https://facebook.com/#{facebook_link}"
    @contact = phone || email || url || facebook_link || twitter_handle
  end

  def strip_url(target_url)
    target_url.gsub('http://', '')
              .gsub('https://', '')
              .gsub('www.', '')
              .gsub(%r{/$}, '')
  end
end
