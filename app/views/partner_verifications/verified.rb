# frozen_string_literal: true

class Views::PartnerVerifications::Verified < Views::Base
  prop :partner, Partner, reader: :private

  def view_template
    content_for(:title) { t('partner_verifications.verified.title') }

    Directory::PageHero(
      title: t('partner_verifications.verified.title'),
      breadcrumb_label: t('partner_verifications.show.breadcrumb')
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose-lg) mx-auto') do
        p(class: 'mb-4') { t('partner_verifications.verified.thanks', partner: partner.name) }
        p(class: 'mb-4') do
          a(href: partner_path(partner), class: 'text-foreground underline hover:decoration-primary') do
            t('partner_verifications.verified.view_listing')
          end
        end
        p do
          plain t('partner_verifications.verified.account_note')
          plain ' '
          mail_to t('contact.email'), class: 'text-foreground underline hover:decoration-primary'
          plain '.'
        end
      end
    end
  end
end
