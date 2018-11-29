# frozen_string_literal: true

# app/components/contact_details/contact_details_component.rb
class ContactDetailsComponent < MountainView::Presenter
  property :phone, default: false
  property :url, default: false
  property :email, default: false
  property :facebook_link, default: false
  property :twitter_handle, default: false

  def twitter_link
    "https://twitter.com/#{twitter_handle}"
  end

  def contact?
    phone || email || url || facebook_link || twitter_handle
  end

  def strip_url(target_url)
    target_url.gsub('http://', '')
              .gsub('https://', '')
              .gsub('www.', '')
  end
end
