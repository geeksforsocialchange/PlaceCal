# frozen_string_literal: true

class Views::Mailers::PartnerVerifications::Invite < Views::Mailers::Base
  prop :partner, Partner, reader: :private
  prop :invited_by_name, String, reader: :private
  prop :verify_url, String, reader: :private

  def email_content
    p { t('mailers.partner_verification.greeting') }
    p { t('mailers.partner_verification.added_by', invited_by: invited_by_name, partner: partner.name) }
    p { t('mailers.partner_verification.what_is_placecal') }
    p { t('mailers.partner_verification.what_happens') }
    p do
      a(href: verify_url,
        style: 'display:inline-block;padding:12px 24px;background-color:#e85e3d;color:#ffffff;' \
               'text-decoration:none;border-radius:24px;font-weight:bold;') do
        t('mailers.partner_verification.verify_button', partner: partner.name)
      end
    end
    p do
      plain t('mailers.partner_verification.not_expected')
      plain ' '
      mail_to t('contact.email')
      plain '.'
    end
    p { t('mailers.partner_digest.sign_off') }
  end
end
