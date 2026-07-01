# frozen_string_literal: true

class Views::EmailPreferences::Expired < Views::Base
  def view_template
    content_for(:title) { t('email_preferences.expired.title') }

    Directory::PageHero(
      title: t('email_preferences.expired.title'),
      breadcrumb_label: t('email_preferences.show.title')
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose-lg) mx-auto') do
        p(class: 'mb-4') { t('email_preferences.expired.body') }
        p do
          plain t('email_preferences.expired.contact')
          plain ' '
          mail_to t('contact.email'), class: 'text-foreground underline hover:decoration-primary'
        end
      end
    end
  end
end
