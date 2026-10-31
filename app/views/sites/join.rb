# frozen_string_literal: true

# The get-in-touch form on a local site, delivered to the site's own contact_email.
class Views::Sites::Join < Views::Base
  theme_scope :get_in_touch,
              parts: { intro: 'The line above the form saying the message goes to the site.' }

  prop :contact_request, ContactRequest, reader: :private
  prop :site, Site, reader: :private

  def view_template
    content_for(:title) { t('sites.join.hero.title') }
    content_for(:description) { site.og_description }

    Shared::Hero(t('sites.join.hero.title'), site.tagline)

    div(class: 'container-editorial py-8') do
      p(**part(:intro, class: 'max-w-(--width-note) mb-6 text-sm leading-normal text-tertiary')) { t('sites.join.intro', site: site.name) }
      UI::Stack(gap: :md) do
        Shared::ContactForm(contact_request:, url: get_in_touch_path, email_cta: false)
        render_email_cta
      end
    end
  end

  private

  # Only shown when the site has published a contact address of its own: the
  # fallback support inbox is an internal detail, not a public address.
  def render_email_cta
    address = site.contact_email
    return if address.blank?

    Shared::EmailCta(heading: t('sites.join.email_cta.heading'), body: t('sites.join.email_cta.body', site: site.name), address:)
  end
end
