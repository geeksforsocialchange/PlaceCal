# frozen_string_literal: true

class ModerationMailer < ApplicationMailer
  def hidden_message(user, partner)
    reason = partner.hidden_reason_html

    mail(to: user.email, subject: 'Your partner has been hidden from PlaceCal') do |format|
      format.html { render Views::Mailers::Moderation::HiddenMessage.new(user: user, partner: partner, reason: reason) }
    end
  end

  def hidden_staff_alert(partner)
    reason = partner.hidden_reason_html
    moderator = User.find(partner.hidden_blame_id)

    mail(to: 'support@placecal.org', subject: 'A partner has been hidden from PlaceCal') do |format|
      format.html { render Views::Mailers::Moderation::HiddenStaffAlert.new(partner: partner, reason: reason, moderator: moderator) }
    end
  end
end
