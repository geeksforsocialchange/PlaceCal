# frozen_string_literal: true

class Components::Shared::ContactDetails < Components::Base
  include Phlex::Rails::Helpers::MailTo

  theme_scope :contact_details,
              parts: {
                root: 'The local-site list of contact lines. The directory card and rows variants have no hooks.',
                item: 'One contact line, its icon then its link; the variant says which. Each line only when the partner has it.'
              },
              variants: { item: %i[phone email website social] },
              tokens: %i[--color-foreground --color-primary]

  # Addresses have no spaces to break at, so they must wrap anywhere to fit 320px
  ADDRESS_LINK = 'min-w-0 wrap-anywhere'

  prop :partner, ::Partner
  prop :email, _Nilable(String), default: nil
  prop :phone, _Nilable(String), default: nil
  prop :url, _Nilable(String), default: nil
  # :card is a self-contained "Get in touch" card; :rows is just the icon rows, for embedding in another card.
  prop :variant, _Union(:sites, :card, :rows), default: :sites
  # :network reads the social links as "Facebook" etc. (sites variant only); the handle moves to the title.
  prop :social_labels, _Union(:handle, :network), default: :handle

  def after_initialize
    @phone ||= @partner.public_phone
    @url ||= @partner.url
    @email ||= @partner.public_email
  end

  def view_template
    case @variant
    when :card then render_card
    when :rows then render_rows
    when :sites then render_sites
    end
  end

  private

  # ── Directory variant ──

  def render_card
    return unless contact?

    UI::Card(variant: :panel, padding: :sm) do
      sidebar_heading(t('directory.contact.get_in_touch'))
      render_rows
    end
  end

  def render_rows
    return unless contact?

    UI::Stack(gap: :sm) do
      contact_row(:contact_phone, @phone, "tel:#{@phone}") if @phone.present?
      contact_row(:contact_email, @email, "mailto:#{@email}") if @email.present?
      contact_row(:contact_website, strip_url(@url), @url) if @url.present?
      @partner.social_profiles.each { contact_row(it.icon, it.label, it.url, network: network_for(it)) }
    end
  end

  def contact_row(icon_name, label, href, network: nil)
    UI::Link(href:, variant: :quiet, target: '_blank', rel: 'noopener', size: :sm, class: 'flex items-center gap-2.5') do
      raw(view_context.icon(icon_name, size: '4'))
      span(class: 'min-w-0 wrap-anywhere') do
        plain label
        network_name(network) if network
      end
    end
  end

  def network_name(network)
    span(class: 'sr-only') { " #{t('directory.contact.on_network', network:)}" }
  end

  # An unrecognised site's label already starts with its host
  def network_for(link)
    link.name if link.known_platform?
  end

  # ── Local-site variant ──

  def render_sites
    p(**part(:root, class: 'grid grid-cols-auto-main gap-x-2 items-center')) do
      render_phone
      render_email
      render_website
      @partner.social_profiles.each { social_link(it) }
      plain t('directory.contact.no_contact') unless contact?
    end
  end

  def render_phone
    return if @phone.blank?

    span(**part(:item, variant: :phone, class: 'contents')) do
      raw(view_context.icon(:contact_phone, size: '4', css_class: 'mt-1'))
      if @partner.valid_public_phone?
        link_to(@phone, "tel:#{@phone}", target: '_blank', rel: 'noopener')
      else
        plain @phone
      end
    end
  end

  def render_email
    return if @email.blank?

    span(**part(:item, variant: :email, class: 'contents')) do
      raw(view_context.icon(:contact_email, size: '4', css_class: 'mt-1'))
      mail_to(@email, @email, target: '_blank', class: ADDRESS_LINK)
    end
  end

  def render_website
    return if @url.blank?

    span(**part(:item, variant: :website, class: 'contents')) do
      raw(view_context.icon(:contact_website, size: '4', css_class: 'mt-1'))
      link_to(strip_url(@url), @url, target: '_blank', rel: 'noopener', class: ADDRESS_LINK)
    end
  end

  def social_link(link)
    span(**part(:item, variant: :social, class: 'contents')) do
      raw(view_context.icon(link.icon, size: '4', css_class: 'mt-1'))
      if @social_labels == :network
        link_to(link.name, link.url, title: link.label, target: '_blank', rel: 'noopener')
      else
        a(href: link.url, target: '_blank', rel: 'noopener', class: ADDRESS_LINK) do
          plain link.label
          network = network_for(link)
          network_name(network) if network
        end
      end
    end
  end

  def contact?
    @phone.present? || @email.present? || @url.present? || @partner.social_links.any?
  end

  def strip_url(target_url)
    target_url.gsub('http://', '').gsub('https://', '').gsub('www.', '').gsub(%r{/$}, '')
  end
end
