# frozen_string_literal: true

class Components::ContactDetails < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :partner, ::Partner
  prop :email, _Nilable(String), default: nil
  prop :phone, _Nilable(String), default: nil
  prop :url, _Nilable(String), default: nil
  prop :variant, _Union(:scss, :tailwind), default: :scss

  def after_initialize
    @phone ||= @partner.public_phone
    @url ||= @partner.url
    @email ||= @partner.public_email
  end

  def view_template
    case @variant
    when :tailwind then render_tailwind
    when :scss then render_scss
    end
  end

  private

  # ── Tailwind variant (directory — will become the only path) ──

  def render_tailwind
    return unless contact?

    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      sidebar_heading('Get in touch')
      div(class: 'flex flex-col gap-2') do
        tailwind_row(:contact_phone, @phone, "tel:#{@phone}") if @phone.present?
        tailwind_row(:contact_email, @email, "mailto:#{@email}") if @email.present?
        tailwind_row(:contact_website, strip_url(@url), @url) if @url.present?
        tailwind_row(:contact_facebook, 'Facebook', "https://facebook.com/#{@partner.facebook_link}") if @partner.facebook_link.present?
        tailwind_row(:contact_twitter, "@#{@partner.twitter_handle}", "https://twitter.com/#{@partner.twitter_handle}") if @partner.twitter_handle.present?
        tailwind_row(:contact_instagram, "@#{@partner.instagram_handle}", "https://www.instagram.com/#{@partner.instagram_handle}/") if @partner.instagram_handle.present?
      end
    end
  end

  def tailwind_row(icon_name, label, href)
    a(href: href, target: '_blank', rel: 'noopener',
      class: 'flex items-center gap-2.5 text-sm text-foreground no-underline hover:underline hover:decoration-primary') do
      raw(view_context.icon(icon_name, size: '4'))
      span(class: 'truncate') { label }
    end
  end

  # ── SCSS variant (local sites — to be removed after Tailwind migration) ──

  def render_scss
    p(class: 'contact_details') do
      render_phone
      render_email
      render_website
      render_facebook
      render_twitter
      render_instagram
      plain 'No contact information - let us know!' unless contact?
    end
  end

  def render_phone
    return if @phone.blank?

    raw(view_context.icon(:contact_phone, size: '4'))
    if @partner.valid_public_phone?
      link_to(@phone, "tel:#{@phone}", target: '_blank', rel: 'noopener')
    else
      plain @phone
    end
  end

  def render_email
    return if @email.blank?

    raw(view_context.icon(:contact_email, size: '4'))
    mail_to(@email, @email, target: '_blank')
  end

  def render_website
    return if @url.blank?

    raw(view_context.icon(:contact_website, size: '4'))
    link_to(strip_url(@url), @url, target: '_blank', rel: 'noopener')
  end

  def render_facebook
    return if @partner.facebook_link.blank?

    raw(view_context.icon(:contact_facebook, size: '4'))
    link_to(@partner.facebook_link, "https://facebook.com/#{@partner.facebook_link}", target: '_blank', rel: 'noopener')
  end

  def render_twitter
    return if @partner.twitter_handle.blank?

    raw(view_context.icon(:contact_twitter, size: '4'))
    link_to("@#{@partner.twitter_handle}", "https://twitter.com/#{@partner.twitter_handle}", target: '_blank', rel: 'noopener')
  end

  def render_instagram
    return if @partner.instagram_handle.blank?

    raw(view_context.icon(:contact_instagram, size: '4'))
    link_to("@#{@partner.instagram_handle}", "https://www.instagram.com/#{@partner.instagram_handle}/", target: '_blank', rel: 'noopener')
  end

  def contact?
    @phone.present? || @email.present? || @url.present? ||
      @partner.facebook_link.present? || @partner.twitter_handle.present? || @partner.instagram_handle.present?
  end

  def strip_url(target_url)
    target_url.gsub('http://', '').gsub('https://', '').gsub('www.', '').gsub(%r{/$}, '')
  end
end
