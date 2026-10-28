# frozen_string_literal: true

class Components::Shared::ContactDetails < Components::Base
  include Phlex::Rails::Helpers::MailTo

  prop :partner, ::Partner
  prop :email, _Nilable(String), default: nil
  prop :phone, _Nilable(String), default: nil
  prop :url, _Nilable(String), default: nil
  # :tailwind renders a self-contained "Get in touch" card; :tailwind_rows
  # renders just the icon rows for embedding in another card (e.g. the event
  # page's organiser SidebarCard).
  prop :variant, _Union(:sites, :tailwind, :tailwind_rows), default: :sites
  # :network reads the social links as "Facebook" etc. (sites variant only); the handle moves to the title.
  prop :social_labels, _Union(:handle, :network), default: :handle

  def after_initialize
    @phone ||= @partner.public_phone
    @url ||= @partner.url
    @email ||= @partner.public_email
  end

  def view_template
    case @variant
    when :tailwind then render_tailwind
    when :tailwind_rows then render_tailwind_rows
    when :sites then render_sites
    end
  end

  private

  # ── Directory variant ──

  def render_tailwind
    return unless contact?

    UI::Card(variant: :panel, padding: :sm) do
      sidebar_heading(t('directory.contact.get_in_touch'))
      render_tailwind_rows
    end
  end

  def render_tailwind_rows
    return unless contact?

    div(class: 'flex flex-col gap-2') do
      tailwind_row(:contact_phone, @phone, "tel:#{@phone}") if @phone.present?
      tailwind_row(:contact_email, @email, "mailto:#{@email}") if @email.present?
      tailwind_row(:contact_website, strip_url(@url), @url) if @url.present?
      tailwind_row(:contact_facebook, 'Facebook', "https://facebook.com/#{@partner.facebook_link}") if @partner.facebook_link.present?
      tailwind_row(:contact_twitter, "@#{@partner.twitter_handle}", "https://twitter.com/#{@partner.twitter_handle}") if @partner.twitter_handle.present?
      tailwind_row(:contact_instagram, "@#{@partner.instagram_handle}", "https://www.instagram.com/#{@partner.instagram_handle}/") if @partner.instagram_handle.present?
    end
  end

  def tailwind_row(icon_name, label, href)
    UI::Link(href:, variant: :quiet, target: '_blank', rel: 'noopener', class: 'flex items-center gap-2.5 text-sm') do
      raw(view_context.icon(icon_name, size: '4'))
      span(class: 'truncate') { label }
    end
  end

  # ── Local-site variant ──

  def render_sites
    p(class: 'contact_details grid grid-cols-auto-main gap-x-2 items-center') do
      render_phone
      render_email
      render_website
      render_facebook
      render_twitter
      render_instagram
      plain t('directory.contact.no_contact') unless contact?
    end
  end

  def render_phone
    return if @phone.blank?

    span(class: 'contact_details__item contents') do
      raw(view_context.icon(:contact_phone, size: '4', css_class: 'mt-1'))
      if @partner.valid_public_phone?
        link_to(@phone, "tel:#{@phone}", target: '_blank', rel: 'noopener', class: 'contact_details__phone')
      else
        plain @phone
      end
    end
  end

  def render_email
    return if @email.blank?

    span(class: 'contact_details__item contents') do
      raw(view_context.icon(:contact_email, size: '4', css_class: 'mt-1'))
      mail_to(@email, @email, target: '_blank', class: 'contact_details__email')
    end
  end

  def render_website
    return if @url.blank?

    span(class: 'contact_details__item contents') do
      raw(view_context.icon(:contact_website, size: '4', css_class: 'mt-1'))
      link_to(strip_url(@url), @url, target: '_blank', rel: 'noopener', class: 'contact_details__website')
    end
  end

  def render_facebook
    return if @partner.facebook_link.blank?

    social_link(:facebook, @partner.facebook_link, "https://facebook.com/#{@partner.facebook_link}")
  end

  def render_twitter
    return if @partner.twitter_handle.blank?

    social_link(:twitter, "@#{@partner.twitter_handle}", "https://twitter.com/#{@partner.twitter_handle}")
  end

  def render_instagram
    return if @partner.instagram_handle.blank?

    social_link(:instagram, "@#{@partner.instagram_handle}", "https://www.instagram.com/#{@partner.instagram_handle}/")
  end

  def social_link(network, handle, href)
    span(class: 'contact_details__item contact_details__item--social contents') do
      raw(view_context.icon(:"contact_#{network}", size: '4', css_class: 'mt-1'))
      if @social_labels == :network
        link_to(t("directory.contact.networks.#{network}"), href, title: handle, target: '_blank', rel: 'noopener', class: "contact_details__#{network}")
      else
        link_to(handle, href, target: '_blank', rel: 'noopener', class: "contact_details__#{network}")
      end
    end
  end

  def contact?
    @phone.present? || @email.present? || @url.present? ||
      @partner.facebook_link.present? || @partner.twitter_handle.present? || @partner.instagram_handle.present?
  end

  def strip_url(target_url)
    target_url.gsub('http://', '').gsub('https://', '').gsub('www.', '').gsub(%r{/$}, '')
  end
end
