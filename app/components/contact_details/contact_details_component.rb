# frozen_string_literal: true

# app/components/contact_details/contact_details_component.rb
class ContactDetailsComponent < MountainView::Presenter
  property :phone, default: false
  property :url, default: false
  property :email, default: false
  property :twitter_handle, default: false
  property :is_valid_phone, default: false

  def twitter_url
    "https://twitter.com/#{twitter_handle}"
  end

  def contact?
    phone || email || url || twitter_handle
  end

  def strip_url(target_url)
    target_url.gsub('http://', '')
              .gsub('https://', '')
              .gsub('www.', '')
              .gsub(/\/$/, '')
  end
end
