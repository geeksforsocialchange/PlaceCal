# frozen_string_literal: true

class Views::Mailers::PartnerVerifications::InviteText < Views::TextBase
  prop :partner, Partner, reader: :private
  prop :invited_by_name, String, reader: :private
  prop :verify_url, String, reader: :private

  def text_content
    [
      t('mailers.partner_verification.greeting'),
      t('mailers.partner_verification.added_by', invited_by: invited_by_name, partner: partner.name),
      t('mailers.partner_verification.what_is_placecal'),
      t('mailers.partner_verification.what_happens'),
      "#{t('mailers.partner_verification.verify_button', partner: partner.name)}: #{verify_url}",
      "#{t('mailers.partner_verification.not_expected')} #{t('contact.email')}",
      t('mailers.partner_digest.sign_off')
    ].join("\n\n")
  end
end
