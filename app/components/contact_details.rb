# frozen_string_literal: true

class Components::ContactDetails < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :partner, ::Partner
  prop :email, _Nilable(String), default: nil
  prop :phone, _Nilable(String), default: nil
  prop :url, _Nilable(String), default: nil

  def after_initialize
    @phone ||= @partner.public_phone
    @url ||= @partner.url
    @email ||= @partner.public_email
  end

  def view_template
    p(class: 'contact_details') do
      render_phone
      render_email
      render_website
      render_facebook
      render_twitter
      render_instagram
      plain 'No contact information - let us know!' unless any_contact?
    end
  end

  private

  def render_phone
    return if @phone.blank?

    strong(class: 'icon icon--contact icon--phone') { 'Phone:' }
    span do
      if @partner.valid_public_phone?
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
    return if @partner.facebook_link.blank?

    strong(class: 'icon icon--contact icon--facebook') { 'Facebook:' }
    span { link_to(@partner.facebook_link, "https://facebook.com/#{@partner.facebook_link}", target: '_blank', rel: 'noopener') }
  end

  def render_twitter
    return if @partner.twitter_handle.blank?

    strong(class: 'icon icon--contact icon--twitter') { 'Twitter:' }
    span { link_to("@#{@partner.twitter_handle}", "https://twitter.com/#{@partner.twitter_handle}", target: '_blank', rel: 'noopener') }
  end

  def render_instagram
    return if @partner.instagram_handle.blank?

    strong(class: 'icon icon--contact icon--instagram') { 'Instagram:' }
    span { link_to("@#{@partner.instagram_handle}", "https://www.instagram.com/#{@partner.instagram_handle}/", target: '_blank', rel: 'noopener') }
  end

  def any_contact?
    @phone.present? || @email.present? || @url.present? || @partner.facebook_link.present? || @partner.twitter_handle.present?
  end

  def strip_url(target_url)
    target_url.gsub('http://', '')
              .gsub('https://', '')
              .gsub('www.', '')
              .gsub(%r{/$}, '')
  end
end
