# frozen_string_literal: true

# The "get in touch" form as it appears on a local site (#3368, D8).
#
# The field set, form markup and validation are identical to the directory
# form, so this subclasses it rather than duplicating ~100 lines of form
# rendering; only the page chrome (hero, intro, email CTA) is site-specific.
# The enquiry is delivered to the site's own contact_email (D13).
class Views::Sites::Join < Views::Directory::Join
  prop :site, Site, reader: :private

  def view_template
    content_for(:title) { t('sites.join.hero.title') }
    content_for(:description) { site.og_description }

    Hero(t('sites.join.hero.title'), site.tagline)

    div(class: 'container-editorial py-8') do
      p(class: 'join-note mb-6') { t('sites.join.intro', site: site.name) }
      render_form
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
