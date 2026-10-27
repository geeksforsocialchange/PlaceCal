# frozen_string_literal: true

class ModerationMailer < ApplicationMailer
  def hidden_message(user, partner)
    reason = partner.hidden_reason_html

    mail(to: user.email, subject: t('mailers.moderation.hidden_message.subject')) do |format|
      format.html { render Views::Mailers::Moderation::HiddenMessage.new(user:, partner:, reason:) }
    end
  end

  def hidden_staff_alert(partner)
    reason = partner.hidden_reason_html
    moderator = User.find(partner.hidden_blame_id)

    mail(to: 'support@placecal.org', subject: t('mailers.moderation.hidden_staff_alert.subject')) do |format|
      format.html { render Views::Mailers::Moderation::HiddenStaffAlert.new(partner:, reason:, moderator:) }
    end
  end
end
