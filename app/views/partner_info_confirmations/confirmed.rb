# frozen_string_literal: true

class Views::PartnerInfoConfirmations::Confirmed < Views::Base
  def view_template
    content_for(:title) { t('partner_info_confirmations.confirmed.title') }

    Directory::PageHero(
      title: t('partner_info_confirmations.confirmed.title'),
      breadcrumb_label: t('partner_info_confirmations.confirmed.title')
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose-lg) mx-auto') do
        p(class: 'mb-4') { t('partner_info_confirmations.confirmed.thanks') }
        p do
          plain t('partner_info_confirmations.confirmed.sign_in_prompt')
          plain ' '
          a(href: new_user_session_path, class: 'text-foreground underline hover:decoration-primary') do
            t('partner_info_confirmations.confirmed.sign_in')
          end
        end
      end
    end
  end
end
