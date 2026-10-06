# frozen_string_literal: true

# The get-in-touch form on a local site, delivered to the site's own contact_email.
class Views::Sites::Join < Views::Base
  register_output_helper :icon

  prop :contact_request, ContactRequest, reader: :private
  prop :site, Site, reader: :private

  def view_template
    content_for(:title) { t('sites.join.hero.title') }
    content_for(:description) { site.og_description }

    Shared::Hero(t('sites.join.hero.title'), site.tagline)

    div(class: 'container-editorial py-8') do
      p(class: 'join-note mb-6') { t('sites.join.intro', site: site.name) }
      Shared::ContactForm(contact_request: contact_request, url: get_in_touch_path, email_cta: false)
      render_email_cta
    end
  end

  private

  # Only shown when the site has published a contact address of its own: the
  # fallback support inbox is an internal detail, not a public address.
  def render_email_cta
    address = site.contact_email
    return if address.blank?

    div(class: 'join-email-cta') do
      div do
        h2(class: 'join-email-cta__heading') { t('sites.join.email_cta.heading') }
        p(class: 'join-email-cta__body') { t('sites.join.email_cta.body', site: site.name) }
      end
      a(href: "mailto:#{address}", class: 'join-email-link with-no-sass') do
        icon(:mail, size: '4')
        plain address
      end
    end
  end
end
