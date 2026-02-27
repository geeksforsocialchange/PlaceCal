# frozen_string_literal: true

class Components::ContactDetails < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :partner, ::Partner
  prop :email, _Nilable(String), default: nil
  prop :phone, _Nilable(String), default: nil
  prop :url, _Nilable(String), default: nil

  def after_initialize
    @name = @partner.name
    @phone ||= @partner.public_phone
    @url ||= @partner.url
    @email ||= @partner.public_email
    @facebook_link = @partner.facebook_link
    @twitter_handle = @partner.twitter_handle
    @instagram_handle = @partner.instagram_handle
    @is_valid_phone = @phone.present? || @partner.valid_public_phone?
    @twitter_url = "https://twitter.com/#{@partner.twitter_handle}"
    @facebook_url = "https://facebook.com/#{@partner.facebook_link}"
    @contact = @phone || @email || @url || @partner.facebook_link || @partner.twitter_handle
  end

  def view_template
    p(class: 'contact_details') do
      render_phone
      render_email
      render_website
      render_facebook
      render_twitter
      render_instagram
      plain 'No contact information - let us know!' unless @contact
    end
  end

  private

  def render_phone
    return if @phone.blank?

    strong(class: 'icon icon--contact icon--phone') { 'Phone:' }
    span do
      if @is_valid_phone
        link_to(@phone, "tel:#{@phone}", target: '_blank', rel: 'noopener')
      else
        plain @phone
      end
    end
  end

  def render_email
    return if @email.blank?

    strong(class: 'icon icon--contact icon--email') { 'Email:' }
    span { mail_to(@email, @email, target: '_blank') }
  end

  def render_website
    return if @url.blank?

    strong(class: 'icon icon--contact icon--website') { ' Website:' }
    span { link_to(strip_url(@url), @url, target: '_blank', rel: 'noopener') }
  end

  def render_facebook
    return if @facebook_link.blank?

    strong(class: 'icon icon--contact icon--facebook') { 'Facebook:' }
    span { link_to(@facebook_link, @facebook_url, target: '_blank', rel: 'noopener') }
  end

  def render_twitter
    return if @twitter_handle.blank?

    strong(class: 'icon icon--contact icon--twitter') { 'Twitter:' }
    span { link_to("@#{@twitter_handle}", @twitter_url, target: '_blank', rel: 'noopener') }
  end

  def render_instagram
    return if @instagram_handle.blank?

    strong(class: 'icon icon--contact icon--instagram') { 'Instagram:' }
    span { link_to("@#{@instagram_handle}", "https://www.instagram.com/#{@instagram_handle}/", target: '_blank', rel: 'noopener') }
  end

  def strip_url(target_url)
    target_url.gsub('http://', '')
              .gsub('https://', '')
              .gsub('www.', '')
              .gsub(%r{/$}, '')
  end
end
